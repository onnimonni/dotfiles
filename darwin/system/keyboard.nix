{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  # macOS native window tiling shortcuts (replaces Rectangle.app).
  # Keys = menu item names from Window menu, values = NSUserKeyEquivalents format.
  #
  # Format: @ = Cmd, ^ = Ctrl, then UTF-8 hex bytes of the key's Unicode codepoint.
  # Standard keys use Unicode arrows (e.g. U+2190 = Left Arrow = \xe2\x86\x90).
  # Special keys like PageUp/PageDown/F19/F20 use Unicode Private Use Area (U+F700-F7FF).
  #
  # HACK: Nix "..." strings silently drop backslash on unknown escapes (\x → x).
  # Must double-escape: "\\x" in Nix → literal \x in bash → printf interprets as hex byte.
  # The printf wrapper in shortcutCmds below handles the actual byte conversion.
  #
  # HACK: "Bottom Left"/"Bottom Right" use Ctrl+Cmd+F19/F20 (unused virtual keys) because
  # real keys like Ctrl+Cmd+End conflict with per-app shortcuts (e.g. Notes.app scroll).
  # Karabiner maps fn+ctrl+cmd+{m,period} → ctrl+cmd+{F19,F20} (see karabiner.nix).
  windowShortcuts = {
    "Bottom" = "@^\\xe2\\x86\\xa9"; # Ctrl+Cmd+Return (U+21A9)
    "Bottom Left" = "@^\\xef\\x9c\\x96"; # Ctrl+Cmd+F19 (U+F716) via Karabiner: fn+ctrl+cmd+m
    "Bottom Right" = "@^\\xef\\x9c\\x97"; # Ctrl+Cmd+F20 (U+F717) via Karabiner: fn+ctrl+cmd+.
    "Fill" = "@^\\xe2\\x86\\x93"; # Ctrl+Cmd+Down (U+2193)
    "Left" = "@^\\xe2\\x86\\x90"; # Ctrl+Cmd+Left (U+2190)
    "Right" = "@^\\xe2\\x86\\x92"; # Ctrl+Cmd+Right (U+2192)
    "Top" = "@^\\xe2\\x86\\x91"; # Ctrl+Cmd+Up (U+2191)
    "Top Left" = "@^\\xef\\x9c\\xac"; # Ctrl+Cmd+Page Up (U+F72C)
    "Top Right" = "@^\\xef\\x9c\\xad"; # Ctrl+Cmd+Page Down (U+F72D)
  };

  # Generate: defaults write -g NSUserKeyEquivalents -dict-add "Name" "$(printf '@^\xHH...')"
  # printf converts \xHH hex escapes into raw UTF-8 bytes that macOS defaults can store.
  shortcutCmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value:
      ''/usr/bin/defaults write -g NSUserKeyEquivalents -dict-add "${name}" "$(printf '${value}')"''
    ) windowShortcuts
  );

  # Symbolic hotkeys: id -> { enabled, parameters }
  # HACK: Can't use targets.darwin.defaults.CustomUserPreferences for these because
  # home-manager's `defaults import CustomUserPreferences` writes to a literal
  # "CustomUserPreferences" domain, not to com.apple.symbolichotkeys.
  # PlistBuddy writes directly to the correct plist.
  symbolicHotkeys = {
    # Keyboard > Keyboard Shortcuts... > Keyboard >
    # Move focus to next window = ⌥ + Tab
    "27" = {
      enabled = 1;
      parameters = [
        65535
        48
        524288
      ];
    };
    # Keyboard > Keyboard Shortcuts... > Input Sources >
    # Select previous input source = Ctrl + ⌥ + Space
    "60" = {
      enabled = 1;
      parameters = [
        32
        49
        786432
      ];
    };
    # Disable opening Finder with ⌥ + ⌘ + Space
    "65" = {
      enabled = 0;
      parameters = [
        32
        49
        1572864
      ];
    };
  };

  pb = "/usr/libexec/PlistBuddy";
  plist = "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist";

  setHotkeyCmds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      id:
      { enabled, parameters }:
      ''
        ${pb} -c "Delete :AppleSymbolicHotKeys:${id}" "${plist}" 2>/dev/null || true
        ${pb} \
          -c "Add :AppleSymbolicHotKeys:${id} dict" \
          -c "Add :AppleSymbolicHotKeys:${id}:enabled integer ${toString enabled}" \
          -c "Add :AppleSymbolicHotKeys:${id}:value dict" \
          -c "Add :AppleSymbolicHotKeys:${id}:value:type string standard" \
          -c "Add :AppleSymbolicHotKeys:${id}:value:parameters array" \
          -c "Add :AppleSymbolicHotKeys:${id}:value:parameters:0 integer ${toString (builtins.elemAt parameters 0)}" \
          -c "Add :AppleSymbolicHotKeys:${id}:value:parameters:1 integer ${toString (builtins.elemAt parameters 1)}" \
          -c "Add :AppleSymbolicHotKeys:${id}:value:parameters:2 integer ${toString (builtins.elemAt parameters 2)}" \
          "${plist}"
      ''
    ) symbolicHotkeys
  );
in
{

  # HACK: Manage NSUserKeyEquivalents via activation script instead of
  # targets.darwin.defaults.CustomUserPreferences.NSGlobalDomain because home-manager
  # uses `defaults import` which REPLACES the entire NSGlobalDomain plist, wiping all
  # other global settings. `defaults write -g -dict-add` merges instead.
  #
  # Delete-then-rewrite pattern ensures stale shortcuts are removed (defaults write
  # -dict-add only merges, never removes keys).
  #
  # After darwin-rebuild, run `killall cfprefsd` + restart apps for changes to take effect
  # (cfprefsd caches defaults aggressively).
  home.activation.setKeyEquivalents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
    /usr/bin/defaults delete -g NSUserKeyEquivalents 2>/dev/null || true
    ${shortcutCmds}

    # Symbolic hotkeys (PlistBuddy for nested dict structure)
    ${setHotkeyCmds}

    # HIToolbox: fn/🌐 key = Do Nothing (0), not "Change Input Source" (1)
    /usr/bin/defaults write com.apple.HIToolbox AppleFnUsageType -int 0
    /usr/bin/defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool false
  '';

  home.file = {
    # Custom dvorak keyboard layout made with Ukelele
    "Library/Keyboard Layouts/OnniDvorak.keylayout".source = ./config/OnniDvorak.keylayout;
  };
}
