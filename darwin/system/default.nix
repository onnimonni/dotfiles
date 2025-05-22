{ pkgs, ... }:
{
  imports = [
    ./nix-core.nix
    ./settings.nix
    ./user.nix
    ./homebrew.nix
    ./programs.nix
    ./keyboard.nix
  ];

  # Pretty nice examples for setting up nix-darwin: https://github.com/thurstonsand/nixonomicon

  # The default Nix build user group ID was changed from 30000 to 350.
  # You are currently managing Nix build users with nix-darwin, but your
  # nixbld group has GID 350, whereas we expected 30000.
  ids.gids.nixbld = 350;

  # Allow sudo to use Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Rosetta is installed and we can build x86_64-darwin too
  nix.extraOptions = ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
}
