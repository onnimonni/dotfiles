{ pkgs, ... }:
{
  imports = [
    ./nix-core.nix
    ./settings.nix
    ./user.nix
    ./homebrew.nix
    ./keyboard.nix
  ];

  # Pretty nice examples for setting up nix-darwin: https://github.com/thurstonsand/nixonomicon

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Run Nixos virtual machines so that we can build x86 servers
    utm
    # For deploying new versions to remote bare metal servers
    nixos-rebuild
    # For local development
    devenv
    # To interact with Estonian ID card
    opensc
    # To format nix files properly
    nixfmt-rfc-style
    # To find nix packages
    nix-search-cli
    # To use cache for Midwork
    cachix
    # To encrypt/decrypt secrets
    sops
    # httpie is easier than curl
    httpie
  ];

  # This line is a prerequisite for local building
  # nix.settings.trusted-users = [ "@admin" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  #programs.zsh.enable = true;
  # Also enable fish
  programs.fish = {
    enable = true;
    shellAliases = {
      update-nix = "darwin-rebuild switch --flake ~/.dotfiles/";
    };
  };

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
