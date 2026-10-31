{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  agySettingsBase = builtins.toJSON {
    permissions.allow = [ "read_file(/nix/store)" ];
  };
in
{
  # Install Google AI tools via homebrew cask
  homebrew.casks = [
    "antigravity"
  ];

  # Home-manager configuration for gemini
  home-manager.users.${username} = {
    home.file = {
      ".gemini/GEMINI.md".text = ''
        # More instructions in
        @~/.agents/AGENTS.md
      '';
    };

    # agy (antigravity-cli) writes settings.json itself (model, trustedWorkspaces),
    # so merge instead of symlinking. Headless -p can't prompt, so pre-allow reading
    # home-manager symlink targets (e.g. AGENTS.md) in /nix/store.
    home.activation.agySettings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"
      BASE_SETTINGS='${agySettingsBase}'

      mkdir -p "$(dirname "$SETTINGS")"
      [ -L "$SETTINGS" ] && rm "$SETTINGS"
      [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

      # Nix base wins for shared keys; union allow-rules so agy-added ones survive
      ${pkgs.jq}/bin/jq -s '.[0] as $nix | .[1] as $cur | ($cur * $nix) | .permissions.allow = (($cur.permissions.allow // []) + ($nix.permissions.allow // []) | unique)' \
        <(echo "$BASE_SETTINGS") "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    '';
  };
}
