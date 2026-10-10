_: {
  homebrew.casks = [
    "maccy"
  ];

  # Prefs can't be managed here: Maccy is sandboxed and macOS blocks
  # `defaults write` into ~/Library/Containers without Full Disk Access.
  # Set manually in Maccy settings:
  # - launch at login, auto update checks
  # - popup: ⌥⌘space, delete: ⌘⌫, pin: ⌘P
  # - history size 1000, hide menu bar icon

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
