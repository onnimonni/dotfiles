{
  pkgs,
  lib,
  ...
}:
let
  mkBashWrappedCli =
    name: realBins:
    pkgs.writeShellScriptBin name ''
      export SHELL=/bin/bash

      for real_bin in ${lib.concatStringsSep " " (map lib.escapeShellArg realBins)}; do
        if [ -x "$real_bin" ]; then
          exec /bin/bash -lc 'export SHELL=/bin/bash; exec "$@"' -- "$real_bin" "$@"
        fi
      done

      echo "${name}: real binary not found" >&2
      exit 127
    '';
in
{
  environment.systemPackages = [
    (mkBashWrappedCli "claude" [ "/opt/homebrew/bin/claude" ])
    (mkBashWrappedCli "codex" [ "/opt/homebrew/bin/codex" ])
    (mkBashWrappedCli "gemini" [ "${pkgs.gemini-cli}/bin/gemini" ])
    (mkBashWrappedCli "opencode" [
      "/opt/homebrew/bin/opencode"
      "/usr/local/bin/opencode"
    ])
  ];
}
