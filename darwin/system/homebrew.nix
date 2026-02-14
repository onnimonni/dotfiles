# Custom nix rules to use determinate nix installer with nix-darwin
{ lib, pkgs, ... }:
{
  # Import all nix files from the 'apps' directory
  # Source: https://www.reddit.com/r/NixOS/comments/1gcmce1/recursively_import_nix_files_from_a_directory/
  imports = lib.filter (n: lib.strings.hasSuffix ".nix" n) (lib.filesystem.listFilesRecursive ./apps);

  # Patch brew bundle to use `mas get` instead of `mas install` for App Store apps
  # `mas install` fails on fresh Apple Accounts with "Redownload Unavailable"
  # `mas get` handles both fresh installs and re-downloads
  # Upstream issue: https://github.com/Homebrew/brew/issues/21559
  # PR: https://github.com/onnimonni/brew/pull/1
  system.activationScripts.preActivation.text = ''
    MAS_INSTALLER="/opt/homebrew/Library/Homebrew/bundle/mac_app_store_installer.rb"
    if [ -f "$MAS_INSTALLER" ]; then
      if ${lib.getExe pkgs.gnugrep} -q '"mas", "install"' "$MAS_INSTALLER"; then
        echo "Patching brew bundle: mas install -> mas get (Homebrew/brew#21559)..."
        ${lib.getExe pkgs.sd} '"mas", "install"' '"mas", "get"' "$MAS_INSTALLER"
      fi
    fi
  '';

  homebrew = {
    enable = true;

    onActivation = {
      # TODO: errors from homebrew on uninstall, programs aren't actually cleaned up.
      # This can likely be fixed by using nixpkgs emacs
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
      extraFlags = [
        "--verbose"
      ];
    };

    # Stop being annoyed by Apple "protecting" me
    caskArgs.no_quarantine = true;

    taps = [ ];

    brews = [
      # To be able to install apps from the app store
      "mas"

      # FIXME: Version from nixpkgs does not build
      # Download files areena.yle.fi for personal archiving
      "yle-dl"

      # Hetzner cloud management
      "hcloud"

      # AWS cli for terraform, public s3 buckets, SES, etc
      "awscli"

      # Docker/container management
      "container"
    ];

    casks = [
      # Terminal emulator
      "ghostty"

      "google-chrome"
      "spotify"

      # Editors
      # VS Code is installed via home-manager in programs/vscode.nix
      "cursor"

      # To play with elixir
      "livebook"

      # TODO: Figure out how to use settings from karabiner json
      "karabiner-elements"

      # Social
      "slack"
      "whatsapp"
      "telegram"
      "discord"

      # Notes and releasing blogs to https://flaky.build
      "notion"

      # Easier markdown editing with nice copy paste
      "typora"

      # For video playback
      "vlc"

      # Forcing newer MacOS on old Macbooks
      "opencore-patcher"

      # Estonian identity cards and signing
      # See also the masApps below
      "open-eid"

      # To edit SVG files
      "inkscape"

      # RSS reader
      "netnewswire"

      # Running local LLM
      "lm-studio"
    ];

    masApps = {
      # Remove stupid cookie banners etc
      "1Blocker" = 1365531024;

      # To force machine to stay alive
      "Amphetamine" = 937984704;

      # MacOS office suite
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;

      # To use iOS simulator
      "Xcode" = 497799835;

      # Estonian identity cards and signing
      "DigiDoc4" = 1370791134;
      "Web eID" = 1576665083;

      # To be able to interact with Victron Power devices
      "VictronConnect" = 1084677271;

      # To fix openstreetmaps issues on macOS
      "Go Map!!" = 592990211;

      # Great topo maps viewer from https://github.com/PasiSalenius
      "Maptrails" = 1524211335;
    };
  };
}
