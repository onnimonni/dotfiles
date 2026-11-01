# DwarfStar (ds4) local LLM inference: https://github.com/antirez/ds4
# Built from the checkout in ~/Projects/ds4 (`make`), not by nix: the binaries
# read their Metal kernel sources and default model (ds4flash.gguf) relative
# to the current directory. These wrappers point both at the checkout so the
# commands work from any directory. DS4_HOME overrides the checkout path.
{ pkgs, lib, ... }:
let
  binaries = [
    "ds4"
    "ds4-server"
    "ds4-agent"
    "ds4-bench"
    "ds4-eval"
  ];

  wrapper =
    name:
    pkgs.writeShellScriptBin name ''
      DS4_HOME="''${DS4_HOME:-$HOME/Projects/ds4}"
      if [ ! -x "$DS4_HOME/${name}" ]; then
        echo "${name}: $DS4_HOME/${name} not found, run make in $DS4_HOME" >&2
        exit 127
      fi

      # Each metal/NAME.metal can be overridden with DS4_METAL_<NAME>_SOURCE
      for source in "$DS4_HOME"/metal/*.metal; do
        kernel=$(basename "$source" .metal)
        var="DS4_METAL_$(printf '%s' "$kernel" | tr '[:lower:]' '[:upper:]')_SOURCE"
        if [ -z "''${!var:-}" ]; then
          export "$var=$source"
        fi
      done

      # Default model of the checkout unless one is given
      model=()
      if [ -e "$DS4_HOME/ds4flash.gguf" ]; then
        model=(-m "$DS4_HOME/ds4flash.gguf")
        for arg in "$@"; do
          case "$arg" in
            -m | --model | --model=*) model=() ;;
          esac
        done
      fi

      exec "$DS4_HOME/${name}" "''${model[@]}" "$@"
    '';
in
{
  environment.systemPackages = map wrapper binaries;
}
