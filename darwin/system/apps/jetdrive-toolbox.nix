{...}:
rec {
  homebrew.casks = [
    "jetdrive-toolbox"
  ];

  system.defaults.CustomUserPreferences."com.transcend.JetDriveToolbox-v2" = {
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
