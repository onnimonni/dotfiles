# Custom nix rules to use determinate nix installer with nix-darwin
{ lib, ... }:
{
  # Import all nix files from the 'apps' directory
  # Source: https://www.reddit.com/r/NixOS/comments/1gcmce1/recursively_import_nix_files_from_a_directory/
  imports = lib.filter
              (n: lib.strings.hasSuffix ".nix" n)
              (lib.filesystem.listFilesRecursive ./apps);

  homebrew = {
    enable = true;

    onActivation = {
      # TODO: errors from homebrew on uninstall, programs aren't actually cleaned up.
      # This can likely be fixed by using nixpkgs emacs
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };

    # Stop being annoyed by Apple "protecting" me
    caskArgs.no_quarantine = true;

    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "onnimonni/tap"
    ];

    brews = [
      # TODO: Somehow the nix enabled shell doesn't work?
      "fish"
    ];

    casks = [
      "jetdrive-toolbox"
      "google-chrome"
      "finicky"
      "spotify"
      "visual-studio-code"
      "karabiner-elements"
      "rectangle"
      "iterm2"
    ];
  };
}
