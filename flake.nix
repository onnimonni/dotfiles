{
  description = "Example Darwin system flake, TODO: replace homebrew";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-rosetta-builder, home-manager }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        # Run Nixos virtual machines so that we can build x86 servers
        pkgs.utm
      ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";
      nix.settings.extra-nix-path = "nixpkgs=flake:nixpkgs";

      # This line is a prerequisite for local building
      nix.settings.trusted-users = [ "@admin" ];

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

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

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
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Onnis-MacBook-Pro
    darwinConfigurations."Onnis-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration

        # An existing Linux builder is needed to initially bootstrap `nix-rosetta-builder`.
        # If one isn't already available: comment out the `nix-rosetta-builder` module below,
        # uncomment this `linux-builder` module, and run `darwin-rebuild switch`:
        { nix.linux-builder.enable = true; }
        # Then: uncomment `nix-rosetta-builder`, remove `linux-builder`, and `darwin-rebuild switch`
        # a second time. Subsequently, `nix-rosetta-builder` can rebuild itself.
        #nix-rosetta-builder.darwinModules.default
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Onnis-MacBook-Pro".pkgs;
  };
}
