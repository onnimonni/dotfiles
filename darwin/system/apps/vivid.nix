{...}:
rec {
  homebrew.casks = [ "vivid" ];

  system.defaults.CustomUserPreferences."com.goodsnooze.vivid" = {
    SUAutomaticallyUpdate = false;
    SUEnableAutomaticChecks = false;
    SUHasLaunchedBefore = true;
    eclipseEnabled = true;
    hasEnabledEclipseOnce = true;
    launchType = "Launch and Enable";
    newInstallSent = true;
    seenOnboarding = true;
    seenV2Onboarding = true;
    showDockIcon = false;
    userHasValidLicense = true;
  };
}
