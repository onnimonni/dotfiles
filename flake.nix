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
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Onnis-MacBook-Pro
    darwinConfigurations."Onnis-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        home-manager.darwinModules.home-manager

        # Set Git commit hash for darwin-version.
        { system.configurationRevision = self.rev or self.dirtyRev or null;}
        # An existing Linux builder is needed to initially bootstrap `nix-rosetta-builder`.
        # If one isn't already available: comment out the `nix-rosetta-builder` module below,
        # uncomment this `linux-builder` module, and run `darwin-rebuild switch`:
        #{ nix.linux-builder.enable = true; }
        # Then: uncomment `nix-rosetta-builder`, remove `linux-builder`, and `darwin-rebuild switch`
        # a second time. Subsequently, `nix-rosetta-builder` can rebuild itself.
        nix-rosetta-builder.darwinModules.default
        
        ./darwin/system
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Onnis-MacBook-Pro".pkgs;
  };
}
