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
    # Download youtube videos offline
    yt-dlp

    # Video conversions and what not
    ffmpeg

    # Activate devenv and other environment variables automatically
    direnv

    # Image conversions
    imagemagick

    # Better than ssh for shitty connections
    mosh

    # For generating passwords
    pwgen

    # Node
    nodejs
    pnpm

    # Python
    uv

    # Read overturemaps data from azure blob storage with 'azcopy'
    azure-storage-azcopy

    # Let Google wreck havoc both on my privacy and my machine
    gemini-cli

    # Run docker on MacOS
    colima
    docker-client

    # Secret management
    sops
    age-plugin-se

    # For converting AI generated png images to svg
    potrace
    vtracer

    # To remember how command line works
    tldr
  ];
}
