{pkgs, lib, osConfig, ...}:
{

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
            parameters = [65535 48 524288];
            type = "standard";
          };
        };
        # Disable opening Finder with ⌥ + ⌘ + space
        "65" = {
          enabled = 0;
          value = {
            parameters = [32 49 1572864];
            type = "standard";
          };
        };
      };
    };

    # Disable automatic period substitution by double-tapping space.
    NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;

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
