# DwarfStar (antirez/ds4): local DeepSeek V4 / GLM 5.3 / Qwen3.8 inference on Metal.
# Not in nixpkgs yet (NixOS/nixpkgs#565378). Adapted from aciceri/nur.
# Update the pin with ./scripts/update-ds4.sh.
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  coreutils,
  curl,
  gnused,
  apple-sdk_26,
  darwinMinVersionHook,
  # Shell words prepended to ds4, ds4-agent and ds4-server args (expanded at
  # runtime, so $HOME works). Later -m/--ctx on the command line win.
  defaultFlags ? [ ],
}:
let
  pin = lib.importJSON ./ds4.json;
in
stdenv.mkDerivation {
  pname = "ds4";
  inherit (pin) version;

  src = fetchFromGitHub {
    owner = "antirez";
    repo = "ds4";
    inherit (pin) rev hash;
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    # Metal 4 tensor API probe is gated on SDK >= 26
    apple-sdk_26
    (darwinMinVersionHook "26.0")
  ];

  dontConfigure = true;
  enableParallelBuilding = true;

  # -mcpu=native is impure; heavy lifting happens on the GPU anyway
  makeFlags = [ "NATIVE_CPU_FLAG=" ];

  # ds4 reads Metal shader sources at runtime relative to cwd unless
  # DS4_METAL_*_SOURCE points elsewhere. Derive the env list from ds4_metal.m
  # so new kernels don't need a manual update here.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/ds4
    cp -R metal $out/share/ds4/

    metalArgs=()
    while read -r env file; do
      [ -f "$out/share/ds4/$file" ] || { echo "missing $file" >&2; exit 1; }
      metalArgs+=(--set "$env" "$out/share/ds4/$file")
    done < <(grep -oE '@"DS4_METAL_[A-Z0-9_]+_SOURCE", *@"metal/[a-z0-9_]+\.metal"' ds4_metal.m |
      sed -E 's/@"([^"]+)", *@"([^"]+)"/\1 \2/')
    [ ''${#metalArgs[@]} -gt 0 ] || { echo "no Metal sources found" >&2; exit 1; }

    for bin in ds4-bench ds4-eval; do
      install -Dm755 $bin $out/libexec/ds4/$bin
      makeWrapper $out/libexec/ds4/$bin $out/bin/$bin "''${metalArgs[@]}"
    done
    for bin in ds4 ds4-server ds4-agent; do
      install -Dm755 $bin $out/libexec/ds4/$bin
      makeWrapper $out/libexec/ds4/$bin $out/bin/$bin "''${metalArgs[@]}" \
        --add-flags ${lib.escapeShellArg (lib.concatStringsSep " " defaultFlags)}
    done

    # Store is read-only: keep models in a per-user dir instead of next to the script
    install -Dm755 download_model.sh $out/bin/ds4-download-model
    substituteInPlace $out/bin/ds4-download-model \
      --replace-fail 'ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)' \
                     'ROOT=''${DS4_ROOT:-$HOME/.local/share/ds4}; mkdir -p "$ROOT"'
    patchShebangs $out/bin/ds4-download-model
    wrapProgram $out/bin/ds4-download-model \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          curl
          gnused
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "DwarfStar: local inference engine for DeepSeek V4, GLM 5.3 and Qwen3.8 (Metal)";
    homepage = "https://github.com/antirez/ds4";
    license = lib.licenses.mit;
    mainProgram = "ds4";
    platforms = [ "aarch64-darwin" ];
  };
}
