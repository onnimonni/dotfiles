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
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  # nix.settings.experimental-features = "nix-command flakes";

  # This line is a prerequisite for local building
  # nix.settings.trusted-users = [ "@admin" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
  # Also enable fish
  programs.fish.enable = true;

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

  # nix-darwin provides a neat Linux builder that runs a NixOS VM as a service in the background. 
  nix.linux-builder.enable = true;

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