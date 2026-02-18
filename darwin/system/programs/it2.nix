# iTerm2 CLI control tool (https://github.com/mkusaka/it2)
# Installed via uvx since it's a Python package not in nixpkgs
{ pkgs, ... }:
let
  it2 = pkgs.writeShellScriptBin "it2" ''
    exec ${pkgs.uv}/bin/uvx it2 "$@"
  '';
in
{
  environment.systemPackages = [ it2 ];
}
