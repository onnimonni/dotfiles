{
  pkgs,
  inputs,
  username,
  ...
}:
{
  # Speak to create text into any field
  homebrew.casks = [
    "handy"
  ];

  # Handy is a Tauri app: no `defaults` domain, settings live in a JSON store
  # it rewrites itself. Patch only the shortcut; skip until first launch
  # creates the file (a partial store could break its deserialization).
  # Restart Handy to pick up the change.
  home-manager.users.${username}.home.activation.handySettings =
    inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
      ''
        handySettings="$HOME/Library/Application Support/com.pais.handy/settings_store.json"
        if [ -f "$handySettings" ]; then
          tmp=$(mktemp)
          ${pkgs.lib.getExe pkgs.jq} '.settings.bindings.transcribe.current_binding = "§"' \
            "$handySettings" > "$tmp" && mv "$tmp" "$handySettings" || rm -f "$tmp"
        fi
      '';
}
