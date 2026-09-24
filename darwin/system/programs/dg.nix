# Decision Graph CLI (dg) + MCP server (dg-mcp), built from upstream flake
{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.dg.packages.${pkgs.stdenv.hostPlatform.system}.dg
  ];
}
