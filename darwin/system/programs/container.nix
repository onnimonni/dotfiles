{ pkgs, ... }:
let
  # Wrapper script that intercepts 'docker' command in bash/zsh
  # Fish already has its own alias in fish.nix
  dockerWrapper = pkgs.writeShellScriptBin "docker" ''
    echo "Error: 'docker' is not available. Use 'container' instead." >&2
    echo "See more: container --help" >&2
    exit 1
  '';
in
{
  environment.systemPackages = [ dockerWrapper ];
}
