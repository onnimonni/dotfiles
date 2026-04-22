# Nix package manager configuration for nix-darwin
{ pkgs, username, ... }:
{
  # Allow unfree software like Claude Code
  nixpkgs.config.allowUnfree = true;

  nix.enable = true;

  nix.settings = {
    trusted-users = [
      "root"
      username
    ];
    warn-dirty = false;
    extra-substituters = [ "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
    keep-outputs = true;
    keep-derivations = true;
    builders-use-substitutes = true;
  };

  # Automatic nix garbage collection and store optimization
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;
}
