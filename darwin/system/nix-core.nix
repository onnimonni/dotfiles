# Custom nix rules to use determinate nix installer with nix-darwin
{ pkgs, ... }:
{
  # Allow unfree software like Claude Code
  nixpkgs.config.allowUnfree = true;

  # Required for use with Determinate Nix
  nix.enable = false;
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = root onnimonni
    warn-dirty = false

    extra-substituters = https://devenv.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  '';
  # Allow unfree packages
  #nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service.
  #services.nix-daemon.enable = true;

  #nix.extraOptions = "experimental-features = nix-command flakes";

  #environment.etc."nix/nix.custom.conf" = {
  #  text = ''
  #    # Determinate nixd handles the /etc/nix/nix.conf
  #    # Custom changes need to go here instead
  #    # Allow using cachix for devenv
  #    extra-substituters = https://devenv.cachix.org
  #    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  #  '';
  #};

  # Try to just append the additional settings normally and trust that nix-darwin will handle it.
  #nix.settings = {
  #  # Not strictly necessary, but this will reduce your disk utilization
  #  builders-use-substitutes = true;
  #  # Determinate nix-installer doesn't include nixpkgs by default
  #  # https://discourse.nixos.org/t/getting-nixpkgs-not-found-error-with-nix-shell/42814/3?u=onnimonni
  #  extra-nix-path = "nixpkgs=flake:nixpkgs";
  #  trusted-users = [ "onnimonni" ];
  #  trusted-substituters = [
  #    "https://cache.nixos.org/"
  #    "https://nix-community.cachix.org"
  #    "https://hyprland.cachix.org"
  #    "https://ghostty.cachix.org"
  #    "https://devenv.cachix.org"
  #  ];
  #  trusted-public-keys = [
  #    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  #    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  #    "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
  #    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  #  ];
  #};
}
