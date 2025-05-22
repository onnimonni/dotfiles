{...}:
{
  homebrew.casks = [
    "copyclip"
  ];

  system.defaults.CustomUserPreferences."com.fiplab.copyclip2" = {
    startAtLogin = true;
    saveClippingsCount = 1000;

    # Disable auto update: use brew instead
    SUEnableAutomaticChecks = false;
    SUAutomaticallyUpdate = false;
    SUHasLaunchedBefore = true;
    SUSendProfileInfo = false;

    # These are needed to skip the first run dialog window
    "com.fiplab.flcore.totalLaunches" = 1;
    "com.fiplab.flcore.updateLaunches" = 1;
    "com.fiplab.flcore.lastUpdateVersion" = "2.9.99.2";

    # Activate with: ⌥ + ⌘ + space
    HotKeyCode = 49;
    HotKeyModifierKey = 1572864;

    # Activate menu with: ^ + ⇧ + space
    MenuHotKeyCode = 49;
    MenuHotKeyModifierKey = 393216;

    # TODO: Figure out how to add my license key
    FLPaddleDidMigrateLicense = true;
  };
}
