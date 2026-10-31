{
  description = "Example Darwin system flake, TODO: replace homebrew";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # devenv from upstream: nixos-unstable lags releases. No nixpkgs follows
    # so binaries hit devenv.cachix.org.
    devenv.url = "github:cachix/devenv/v2.4.0";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Linux builder VM with Rosetta 2 (x86_64-linux at near-native speed)
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Shared worktree/HTTPS daemon; also serves devenv's proxy routes. No
    # nixpkgs follows so binaries hit lazy-cow-tree.cachix.org.
    lazy-cow-tree.url = "github:onnimonni/devenv-lazy-cow-worktrees";
    # `project` CLI + herdr plugin for devenv worktrees
    devenv-agents = {
      url = "github:wyattjoh/devenv-agents";
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
        username = "onnimonni";
        fullName = "Onni Hakala";
        email = "onni@flaky.build";
        # Public Cloudflare zone used by the Mac Studio tunnel. Keep this
        # tracked: git flakes omit gitignored local-user.nix during evaluation.
        shareMacDomain = "fyff.ee";
      };

      # Load local override if exists (gitignored)
      localUserPath = ./local-user.nix;
      localUser = if builtins.pathExists localUserPath then import localUserPath else { };
      userConfig = defaultUser // (builtins.removeAttrs localUser [ "hostname" ]);
      baseHostnames = [
        "Onnis-MacBook-Pro"
        "Onnis-Mac-Studio"
      ];
      hostnames =
        if localUser ? hostname && !(builtins.elem localUser.hostname baseHostnames) then
          baseHostnames ++ [ localUser.hostname ]
        else
          baseHostnames;
      selectedHostname =
        if localUser ? hostname && builtins.elem localUser.hostname hostnames then
          localUser.hostname
        else
          builtins.head hostnames;

      mkDarwinConfig =
        {
          hostname,
          username,
          fullName,
          email,
          shareMacDomain ? null,
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              inputs
              hostname
              username
              fullName
              email
              shareMacDomain
              ;
          };
          modules = [
            home-manager.darwinModules.home-manager
            sops-nix.darwinModules.sops
            inputs.nix-rosetta-builder.darwinModules.default
            { system.configurationRevision = self.rev or self.dirtyRev or null; }
            ./darwin/system
          ];
        };

      mkHostConfig = hostname: userConfig // { inherit hostname; };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#<hostname>
      darwinConfigurations = builtins.listToAttrs (
        map (hostname: {
          name = hostname;
          value = mkDarwinConfig (mkHostConfig hostname);
        }) hostnames
      );

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.${selectedHostname}.pkgs;
    };
}
