# Pinned nixpkgs has 2.1.276; npm has the required 2.1.280 release.
# Keep nixpkgs' wrappers, runtime dependencies and install checks.
# Update the npm pin with ./scripts/update-claude-code.sh.
{
  lib,
  stdenv,
  fetchurl,
  claude-code,
}:
let
  pin = lib.importJSON ./claude-code.json;
  platform = pin.platforms.${stdenv.hostPlatform.system};
  upstreamInstall = "unzstd -q $src -o $out/bin/claude";
  # nixpkgs defaults to the macOS system store only, which fails TLS to
  # api.anthropic.com (UNABLE_TO_GET_ISSUER_CERT_LOCALLY). Keep the bundled
  # roots; "system" still adds keychain CAs such as lazy-cow-tree's.
  upstreamCertStore = "--set-default CLAUDE_CODE_CERT_STORE system";
in
claude-code.overrideAttrs (old: {
  inherit (pin) version;
  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${platform.npm}/-/claude-code-${platform.npm}-${pin.version}.tgz";
    inherit (platform) hash;
  };
  dontUnpack = false;
  sourceRoot = "package";

  # npm contains the native binary in a tarball instead of a zstd stream.
  # Fail visibly if a nixpkgs update changes the installer we adapt.
  installPhase =
    assert lib.assertMsg (lib.hasInfix upstreamInstall old.installPhase)
      "claude-code: nixpkgs installer changed; review the npm override";
    assert lib.assertMsg (lib.hasInfix upstreamCertStore old.installPhase)
      "claude-code: nixpkgs cert store default changed; review the override";
    lib.replaceStrings
      [ upstreamInstall upstreamCertStore ]
      [ "cp claude $out/bin/claude" "--set-default CLAUDE_CODE_CERT_STORE bundled,system" ]
      old.installPhase;

  passthru = old.passthru // {
    updateScript = [
      "bash"
      "./scripts/update-claude-code.sh"
    ];
  };
  meta = old.meta // {
    platforms = lib.attrNames pin.platforms;
  };
})
