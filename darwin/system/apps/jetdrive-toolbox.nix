{ lib, hostname, ... }:
let
  isMacBook = lib.hasInfix "MacBook" hostname;
in
{
  homebrew.casks = lib.optionals isMacBook [
    "jetdrive-toolbox"
  ];

  system.defaults.CustomUserPreferences."com.transcend.JetDriveToolbox-v2" = lib.mkIf isMacBook {
    # Disable auto update: use brew instead
    SUAutomaticallyUpdate = false;
    SUEnableAutomaticChecks = false;
    SUHasLaunchedBefore = true;
    # Accept EULA
    canEnterApp = true;
    # Disable analytics
    canSendGA = false;
  };
}
