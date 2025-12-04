{ pkgs, lib, ... }:
let
  latestOpensc = pkgs.opensc.version;
  # As of 2024-09, latest version is 0.26.1
  expectedVersion = "0.26.1";
  customOpensc = pkgs.opensc.overrideAttrs (oldAttrs: {
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "OpenSC";
      repo = "OpenSC";
      rev = "79f5059135a5ac7b71258b196986e81d71a4256c";
      sha256 = "sha256-WWVW7XhUzPH192D1qV4IEmS7ukKgLgj7xDQtKylk6ho=";
    };
  });
in
{
  # Import all nix files from the 'apps' directory
  # Source: https://www.reddit.com/r/NixOS/comments/1gcmce1/recursively_import_nix_files_from_a_directory/
  imports = lib.filter (n: lib.strings.hasSuffix ".nix" n) (
    lib.filesystem.listFilesRecursive ./programs
  );

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # For deploying new versions to remote bare metal servers
    nixos-rebuild
    # To interact with Estonian ID card
    # As of 2025-09: Support for new Estonian ID cards of 2025 were not yet released
    # FIXME: replace with 'opensc' when the assert below fails
    (
      if (latestOpensc > expectedVersion) then
        (throw "OpenSC ${latestOpensc} is newer than ${expectedVersion}. Custom override can be removed.")
      else
        customOpensc
    )
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

    # Python
    uv

    # Read overturemaps data from azure blob storage with 'azcopy'
    azure-storage-azcopy

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

    # To build C stuff like duckdb
    cmake
  ];
}
