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
    ];

    brews = [
      # TODO: Somehow the nix enabled shell doesn't work?
      #"fish"
    ];

    casks = [
      "google-chrome"
      "spotify"
      "visual-studio-code"
      # TODO: Figure out how to use settings from karabiner json
      "karabiner-elements"
      # TODO: Figure out how to map the ⌥ + ⌫ to wipe word and ⌥ + ⇧ + ⌫ to wipe line
      "iterm2"
      # Social
      "slack"
      "whatsapp"
      "telegram"

      # Estonian identity cards and signing
      # See also the masApps below
      "open-eid"
    ];

    masApps = {
      # Remove stupid cookie banners etc
      "1Blocker" = 1365531024;

      # To force machine to stay alive
      "amphetamine" = 937984704;

      # MacOS office suite
      "keynote" = 409183694;
      "numbers" = 409203825;
      "pages" = 409201541;

      # To use iOS simulator
      "xcode" = 497799835;

      # Estonian identity cards and signing
      "DigiDoc4" = 1370791134;
      "Web eID"  = 1576665083;
    };
  };
}
