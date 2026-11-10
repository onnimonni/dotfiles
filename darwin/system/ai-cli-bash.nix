{
  pkgs,
  lib,
  ...
}:
let
  # NODE_EXTRA_CA_CERTS takes a single file, and project shells set it to their
  # local CA alone (lazy-cow-tree: ~/.local/state/lazy-cow-tree/ca/ca.pem).
  # Claude Code's built-in roots then miss the public chain of its own API
  # ("UNABLE_TO_GET_ISSUER_CERT_LOCALLY"), so hand it one bundle: the public
  # roots plus whatever CA was set. Prints the path to use.
  caBundle = pkgs.writeShellScript "ai-cli-ca-bundle" ''
    roots=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    extra=''${NODE_EXTRA_CA_CERTS:-}
    if [ -z "$extra" ] || [ "$extra" = "$roots" ] || [ ! -r "$extra" ]; then
      echo "$roots"
      exit 0
    fi
    dir=''${XDG_CACHE_HOME:-$HOME/.cache}/ai-cli
    bundle="$dir/ca-bundle-$(cat "$roots" "$extra" | cksum | cut -d' ' -f1).pem"
    if [ ! -s "$bundle" ]; then
      mkdir -p "$dir"
      cat "$roots" "$extra" > "$bundle.$$" && mv "$bundle.$$" "$bundle"
    fi
    echo "$bundle"
  '';

  mkBashWrappedCli =
    name: realBins:
    pkgs.writeShellScriptBin name ''
      export SHELL=/bin/bash

      for real_bin in ${lib.concatStringsSep " " (map lib.escapeShellArg realBins)}; do
        if [ -x "$real_bin" ]; then
          # The bundle is chosen inside the login shell: its profile and
          # project hooks may set NODE_EXTRA_CA_CERTS again.
          exec /bin/bash -lc 'export SHELL=/bin/bash; export NODE_EXTRA_CA_CERTS="$(${caBundle})"; exec "$@"' -- "$real_bin" "$@"
        fi
      done

      echo "${name}: real binary not found" >&2
      exit 127
    '';
in
{
  environment.systemPackages = [
    (mkBashWrappedCli "claude" [ (lib.getExe pkgs.claude-code) ])
    (mkBashWrappedCli "codex" [ "/opt/homebrew/bin/codex" ])
    (mkBashWrappedCli "opencode" [
      "/opt/homebrew/bin/opencode"
      "/usr/local/bin/opencode"
    ])
  ];
}
