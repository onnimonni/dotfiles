{
  description = "Example Darwin system flake, TODO: replace homebrew";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";

    # TODO: This doesn't work nicely with nix-darwin so we won't use it
    #determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      ...
    }:
    let
      # Default user config (can be overridden via local-user.nix)
      defaultUser = {
        hostname = "Onnis-MacBook-Pro";
        username = "onnimonni";
        fullName = "Onni Hakala";
        email = "onni@flaky.build";
      };

      # Load local override if exists (gitignored)
      localUserPath = ./local-user.nix;
      userConfig = if builtins.pathExists localUserPath then import localUserPath else defaultUser;

      mkDarwinConfig =
        {
          hostname,
          username,
          fullName,
          email,
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              inputs
              hostname
              username
              fullName
              email
              ;
          };
          modules = [
            home-manager.darwinModules.home-manager
            sops-nix.darwinModules.sops
            { system.configurationRevision = self.rev or self.dirtyRev or null; }
            ./darwin/system
          ];
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#<hostname>
      darwinConfigurations.${userConfig.hostname} = mkDarwinConfig userConfig;

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.${userConfig.hostname}.pkgs;
    };
}
