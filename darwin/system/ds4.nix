# DwarfStar local LLM, only on Macs that can run it.
# ds4Supported is detected by scripts/generate-local-user.sh (local-user.nix).
{
  pkgs,
  lib,
  ds4Supported,
  ...
}:
lib.mkIf ds4Supported {
  environment.systemPackages = [ (pkgs.callPackage ../packages/ds4 { }) ];
}
