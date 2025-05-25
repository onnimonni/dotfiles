{pkgs, lib, ...}:
{
  # Import all nix files from the 'apps' directory
  # Source: https://www.reddit.com/r/NixOS/comments/1gcmce1/recursively_import_nix_files_from_a_directory/
  imports = lib.filter
              (n: lib.strings.hasSuffix ".nix" n)
              (lib.filesystem.listFilesRecursive ./programs);

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
    # Github cli
    gh
    # Listing files
    tree
    # To test connection speed
    speedtest-go
  ];

  # Also enable fish
  programs.fish = {
    enable = true;
    shellAliases = {
      update-nix = "sudo darwin-rebuild switch --flake ~/.dotfiles/";
    };
  };
}
