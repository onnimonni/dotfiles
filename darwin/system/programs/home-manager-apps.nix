{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  hm = inputs.home-manager.lib.hm;
in
{
  # Create macOS aliases in /Applications for home-manager apps
  # This allows Spotlight and Finder to find nix-installed GUI apps
  home-manager.users.${username} = {
    home.activation.aliasHomeManagerApps = hm.dag.entryAfter [ "writeBoundary" ] ''
      app_folder="$HOME/Applications/Home Manager Apps"
      [ -d "$app_folder" ] || exit 0
      shopt -s nullglob || true
      for app in "$app_folder"/*.app; do
        app_name=$(basename "$app")
        base="''${app_name%.app}"
        # If a real .app directory already lives in /Applications (e.g. brew
        # cask installed it), leave it alone — never overwrite a real install
        # with a Finder alias, and never try to `rm -f` a directory.
        if [ -d "/Applications/$app_name" ] && [ ! -L "/Applications/$app_name" ]; then
          continue
        fi
        # Finder writes the alias as "<base>" (no .app); if a file with that
        # name already exists Finder picks "<base> alias", "<base> alias 2",
        # … Remove all variants before recreating so they don't accumulate.
        # Guard each rm with -f and only delete plain files / symlinks.
        for victim in "/Applications/$app_name" "/Applications/$base"; do
          [ -f "$victim" ] || [ -L "$victim" ] && rm -f "$victim" || true
        done
        /usr/bin/find /Applications -maxdepth 1 -name "$base alias*" -type f -delete 2>/dev/null || true
        /usr/bin/osascript -e "tell app \"Finder\" to make alias file at POSIX file \"/Applications\" to POSIX file \"$app\"" || true
      done
    '';
  };
}
