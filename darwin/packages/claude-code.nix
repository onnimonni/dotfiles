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
    lib.replaceStrings [ upstreamInstall ] [ "cp claude $out/bin/claude" ] old.installPhase;

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
