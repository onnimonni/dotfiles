{ ... }:
{
  homebrew.casks = [
    "maccy"
  ];

  system.defaults.CustomUserPreferences."org.p0deje.Maccy" = {
    launchAtLogin = true;
    SUEnableAutomaticChecks = true;

    # Activate with: ⌥ + ⌘ + space (carbonModifiers: opt=2048 + cmd=256 = 2304, carbonKeyCode: space=49)
    KeyboardShortcuts_popup = "{\"carbonModifiers\":2304,\"carbonKeyCode\":49}";
    # Delete with: ⌘ + backspace
    KeyboardShortcuts_delete = "{\"carbonKeyCode\":51,\"carbonModifiers\":2048}";
    # Pin with: ⌘ + p
    KeyboardShortcuts_pin = "{\"carbonKeyCode\":35,\"carbonModifiers\":2048}";

    # Store 1000 clipboard history items
    historySize = 1000;

    # Hide menu bar icon (use hotkey instead)
    "NSStatusItem VisibleCC Item-1" = false;
  };

  # FIXME: Disable notifications programmatically for Maccy and Tips.app
  # Manual: System Settings > Notifications > [App] > Allow Notifications = off
  #
  # Tried on macOS 26 Tahoe — none of these worked:
  # 1. Writing flags=0 to com.apple.ncprefs.plist (plist updates but UI ignores it)
  # 2. Adding auth=7 field (matches Slack/Spotify disabled entries)
  # 3. Adding src/req code-signing requirement blob via csreq
  # 4. Killing cfprefsd before write to flush cache, then killing usernoted/NotificationCenter after
  # 5. Using PlistBuddy to modify entries
  #
  # macOS 26 appears to read notification state from an in-memory store that doesn't
  # sync from the ncprefs plist on disk. Only the System Settings UI toggle works.
  # Maccy has no built-in preference for this (confirmed in github.com/p0deje/Maccy/issues/692).
  # Tips.app (com.apple.tips) shows annoying notifications after macOS updates.
}
