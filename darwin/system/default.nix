{ pkgs, ... }:
{
  imports = [
    ./nix-core.nix
  ];

  # Pretty nice examples for setting up nix-darwin: https://github.com/thurstonsand/nixonomicon

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    # Run Nixos virtual machines so that we can build x86 servers
    pkgs.utm
    # For deploying new versions to remote bare metal servers
    pkgs.nixos-rebuild
    # For local development
    pkgs.devenv
    # To interact with Estonian ID card
    pkgs.opensc
  ];

  # This line is a prerequisite for local building
  # nix.settings.trusted-users = [ "@admin" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
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
  security.pam.enableSudoTouchIdAuth = true;

  # Setup MacOS defaults
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.LoginwindowText = "Teretulemast Onnimonni";
    screencapture.location = "~/Desktop/Screenshots/";
    screensaver.askForPasswordDelay = 10;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Rosetta is installed and we can build x86_64-darwin too
  nix.extraOptions = ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  users.users.onnimonni = {
      name = "onnimonni";
      home = "/Users/onnimonni";
      shell = pkgs.fish;
  };
}