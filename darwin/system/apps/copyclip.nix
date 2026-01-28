{ ... }:
{
  homebrew.casks = [
    "copyclip"
  ];

  # Launch CopyClip2 at login via launchd
  launchd.user.agents.copyclip2 = {
    command = "/Applications/CopyClip 2.app/Contents/MacOS/CopyClip 2";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  system.defaults.CustomUserPreferences."com.fiplab.copyclip2" = {
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
