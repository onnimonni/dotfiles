{ username, ... }:
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

  # Disable Maccy notifications & sounds via com.apple.ncprefs flags bitmask
  # bit 25 = Allow Notifications, bit 2 = Play Sound
  system.activationScripts.postActivation.text = ''
        NCPREFS="/Users/${username}/Library/Preferences/com.apple.ncprefs.plist"
        BUNDLE_ID="org.p0deje.Maccy"

        if [ -f "$NCPREFS" ]; then
          /usr/bin/python3 -c "
    import plistlib, sys

    prefs_path = '$NCPREFS'
    bundle_id = '$BUNDLE_ID'
    FLAG_ALLOW = 1 << 25
    FLAG_SOUND = 1 << 2

    with open(prefs_path, 'rb') as f:
        data = plistlib.load(f)

    modified = False
    for app in data.get('apps', []):
        if app.get('bundle-id') == bundle_id:
            flags = app.get('flags', 0)
            new_flags = flags & ~FLAG_ALLOW & ~FLAG_SOUND
            if new_flags != flags:
                app['flags'] = new_flags
                modified = True
                print(f'Maccy notifications disabled (flags {flags} -> {new_flags})')
            else:
                print('Maccy notifications already disabled')
            break
    else:
        print('Maccy not yet in ncprefs, skip (will apply on next rebuild after first launch)')
        sys.exit(0)

    if modified:
        with open(prefs_path, 'wb') as f:
            plistlib.dump(data, f)
    "
          killall usernoted 2>/dev/null || true
        fi
  '';
}
