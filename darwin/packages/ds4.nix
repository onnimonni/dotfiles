# DwarfStar (ds4): antirez's local inference engine + native coding agent.
# Source tracks the `ds4` flake input; update with `nix flake update ds4`.
# https://github.com/antirez/ds4
{
  lib,
  stdenv,
  apple-sdk_26,
  darwinMinVersionHook,
  src,
}:
stdenv.mkDerivation {
  pname = "ds4";
  version = "0-unstable-${src.lastModifiedDate or "unknown"}";
  inherit src;

  # Metal residency sets, mathMode and Metal 4 tensor API need SDK 26;
  # residency sets need a macOS 15 target, newer APIs are @available-guarded.
  buildInputs = [
    apple-sdk_26
    (darwinMinVersionHook "15.0")
  ];

  # -mcpu=native would bake the build host's CPU in; M1 baseline runs on both
  # Macs. Heavy lifting happens in Metal kernels compiled at runtime anyway.
  makeFlags = [ "NATIVE_CPU_FLAG=-mcpu=apple-m1" ];
  buildFlags = [
    "ds4"
    "ds4-agent"
    "ds4-server"
  ];
  enableParallelBuilding = true;

  # Script links ds4flash.gguf next to itself, which is the read-only store.
  postPatch = ''
    # shellcheck disable=SC2016 # literal $ROOT/$OUT_DIR in script text
    substituteInPlace download_model.sh --replace-fail 'cd "$ROOT"' 'cd "$OUT_DIR"'
  '';

  # Binaries read metal/*.metal relative to cwd, so keep them in one tree.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/share/ds4
    cp -r ds4 ds4-agent ds4-server metal download_model.sh "$out"/share/ds4/
    runHook postInstall
  '';

  meta = {
    description = "DwarfStar local LLM inference engine and coding agent (Metal)";
    homepage = "https://github.com/antirez/ds4";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
