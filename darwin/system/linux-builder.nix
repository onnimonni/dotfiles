{ pkgs, ... }:

{
  nix.settings.trusted-users = [ "@admin" ];
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 8;

    #package = pkgs.darwin.linux-builder-x86_64;
    #systems = [ "x86_64-linux" ];
    #package = pkgs.darwin.linux-builder;
    systems = [ "aarch64-linux" ];
    config = {
      nix.gc = {
        automatic = true;
        # dates = "weekly";
        options = "--delete-older-than 30d";
      };
      virtualisation = {
        darwin-builder = {
          diskSize = 25 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 8;
      };
    };
  };
}