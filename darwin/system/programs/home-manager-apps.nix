{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  hm = inputs.home-manager.lib.hm;
in
{
  # Create macOS aliases in /Applications for home-manager apps
  # This allows Spotlight and Finder to find nix-installed GUI apps
  home-manager.users.onnimonni = {
    home.activation.aliasHomeManagerApps = hm.dag.entryAfter [ "writeBoundary" ] ''
      app_folder="$HOME/Applications/Home Manager Apps"
      if [ -d "$app_folder" ]; then
        for app in "$app_folder"/*.app; do
          if [ -e "$app" ]; then
            app_name=$(basename "$app")
            # Remove existing alias if present
            if [ -e "/Applications/$app_name" ]; then
              rm -f "/Applications/$app_name"
            fi
            # Create macOS alias using osascript
            /usr/bin/osascript -e "tell app \"Finder\" to make alias file at POSIX file \"/Applications\" to POSIX file \"$app\"" || true
          fi
        done
      fi
    '';
  };
}
