# ds4-agent / ds4-server wrappers picking a model by installed RAM.
# Models live in ~/.ds4/gguf; first launch offers to download the picked one.
# Override with DS4_MODEL=<download target> (see `ds4-download --help`).
# Ctrl+C twice exits: patches/ds4-ctrl-c-twice.patch (applied in packages/ds4.nix).
# https://github.com/onnimonni/dotfiles
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  ds4 = pkgs.callPackage ../../packages/ds4.nix { src = inputs.ds4; };
  share = "${ds4}/share/ds4";

  download = pkgs.writeShellApplication {
    name = "ds4-download";
    runtimeInputs = with pkgs; [
      curl
      python3Packages.huggingface-hub # provides `hf`
    ];
    text = ''
      export DS4_GGUF_DIR="''${DS4_GGUF_DIR:-$HOME/.ds4/gguf}"
      mkdir -p "$DS4_GGUF_DIR"
      # Models are 80-500 GiB; refuse to fill the disk.
      free_gib=$(( $(df -k "$DS4_GGUF_DIR" | awk 'NR==2 {print $4}') / 1024 / 1024 ))
      if [ "$free_gib" -lt 500 ]; then
        echo "ds4-download: only ''${free_gib} GiB free in $DS4_GGUF_DIR, need 500 GiB" >&2
        exit 1
      fi
      exec ${share}/download_model.sh "$@"
    '';
  };

  # Metal sources resolve from cwd, so launch inside the store tree. Only
  # ds4-agent can --chdir back after engine load (its tools need user cwd).
  mkLauncher =
    bin: chdirBack:
    pkgs.writeShellApplication {
      name = bin;
      runtimeInputs = [ download ];
      text = ''
        export DS4_GGUF_DIR="''${DS4_GGUF_DIR:-$HOME/.ds4/gguf}"
        # Download target -> file and default flags. Tiers follow upstream
        # docs/METAL.md + README: Qwen3.8 Q2 is the 64 GB resident option.
        mem_gib=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
        if [ -z "''${DS4_MODEL:-}" ]; then
          if   [ "$mem_gib" -ge 256 ]; then DS4_MODEL=ds4f-q4
          elif [ "$mem_gib" -ge 96 ];  then DS4_MODEL=ds4f-q2
          elif [ "$mem_gib" -ge 64 ];  then DS4_MODEL=qwen38-q2
          else DS4_MODEL=ds4f-q2-ssd
          fi
        fi
        flags=()
        case "$DS4_MODEL" in
          ds4f-q4) file=DeepSeek-V4-Flash-Q4KExperts-F16HC-F16Compressor-F16Indexer-Q8Attn-Q8Shared-Q8Out-chat-v2-imatrix-0731.gguf; flags=(--ctx 65536) ;;
          ds4f-q2) file=DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix-0731.gguf; flags=(--ctx 32768) ;;
          ds4f-q2-ssd) DS4_MODEL=ds4f-q2; file=DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix-0731.gguf; flags=(--ssd-streaming) ;;
          qwen38-q2) file=Qwen3.8-Flash-Next-Q2.gguf; flags=(--ctx 8192 --prefill-chunk 1024) ;;
          qwen38-q4k) file=Qwen3.8-Flash-Next-Q4.gguf ;;
          glm53-q2) file=GLM-5.3-Flash-Q2.gguf; flags=(--ctx 32768) ;;
          *) echo "ds4: unknown DS4_MODEL=$DS4_MODEL" >&2; exit 1 ;;
        esac
        model="$DS4_GGUF_DIR/$file"
        if [ ! -e "$model" ]; then
          echo "${bin}: ''${mem_gib} GiB RAM -> $DS4_MODEL ($model missing)" >&2
          read -r -p "Download it now? Requires 500 GiB free disk. [y/N] " ans
          [[ "$ans" =~ ^[Yy] ]] || { echo "Run: ds4-download $DS4_MODEL" >&2; exit 1; }
          ds4-download "$DS4_MODEL"
        fi
        cd ${share} || exit
        exec ./${bin} -m "$model" "''${flags[@]}" ${lib.optionalString chdirBack ''--chdir "$OLDPWD"''} "$@"
      '';
    };
in
{
  environment.systemPackages = [
    download
    (mkLauncher "ds4-agent" true)
    (mkLauncher "ds4-server" false)
  ];
}
