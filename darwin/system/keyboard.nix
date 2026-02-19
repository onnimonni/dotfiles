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
  '';

  home.file = {
    # Custom dvorak keyboard layout made with Ukelele
    "Library/Keyboard Layouts/OnniDvorak.keylayout".source = ./config/OnniDvorak.keylayout;
  };

  targets.darwin.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      # Keyboard > Keyboard Shortcuts... > Keyboard >
      # Move focus to next window = ⌥ + tab
      AppleSymbolicHotKeys = {
        "27" = {
          enabled = 1;
          value = {
            parameters = [
              65535
              48
              524288
            ];
            type = "standard";
          };
        };
        # Disable opening Finder with ⌥ + ⌘ + space
        "65" = {
          enabled = 0;
          value = {
            parameters = [
              32
              49
              1572864
            ];
            type = "standard";
          };
        };
      };
    };

    "com.apple.HIToolbox" = {
      # Source: https://macos-defaults.com/keyboard/applefnusagetype.html
      # Don't do anything when pressing the fn/globe key
      AppleDictationAutoEnable = false;

      # Add my custom keyboard layout to the system
      AppleCurrentKeyboardLayoutInputSourceID = "org.unknown.keylayout.ONNIDVORAK-QWERTYCMD";
      AppleEnabledInputSources = [
        {
          InputSourceKind = "AppleKeyboardLayout";
          "KeyboardLayout ID" = "org.unknown.keylayout.ONNIDVORAK-QWERTYCMD";
        }
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 17;
          "KeyboardLayout Name" = "Finnish";
        }
      ];
    };
  };
}
