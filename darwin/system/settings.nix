# Custom nix rules to use determinate nix installer with nix-darwin
{ pkgs, ... }:
{
  # Setup MacOS defaults
  system.defaults = {
    # dock settings
    dock = {
      # auto show and hide dock
      autohide = true;
      # decrease delay for showing dock
      autohide-delay = 0.2;
      # how fast is the dock showing animation
      autohide-time-modifier = 0.2;
      expose-animation-duration = 0.2;
      tilesize = 48;
      launchanim = false;
      static-only = false;
      showhidden = true;
      show-recents = false;
      show-process-indicators = true;
      orientation = "bottom";
      mru-spaces = false;
      # mouse in top right corner will (5) start screensaver
      wvous-tr-corner = 5;
    };
    screensaver = {
      # ask for password immediately after screensaver starts
      askForPassword = true;
      # ask for password after 5 seconds
      askForPasswordDelay = 5;
    };

    finder = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      FXDefaultSearchScope = "SCcf"; # When performing a search, search the current folder by default
      ShowPathbar = true;
      _FXSortFoldersFirst = true; # keep folders on top when sorting by name
      AppleShowAllExtensions = true; # show all file extensions
      FXPreferredViewStyle = "clmv"; # list view
    };

    # Store screenshots in separate folder
    screencapture.location = "~/Desktop/Screenshots/";

    NSGlobalDomain = {
      # Allows accented characters to be typed by holding the key down
      ApplePressAndHoldEnabled = true;
    };
  };

  system.defaults.CustomUserPreferences = {
    # Allow more icons into the menu bar
    # Source: https://flaky.build/built-in-workaround-for-applications-hiding-under-the-macbook-pro-notch
    globalDomain = {
      NSStatusItemSelectionPadding = 6;
      NSStatusItemSpacing = 6;
    };
    "com.apple.desktopservices" = {
      # Avoid creating .DS_Store files on network or USB volumes
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    "com.apple.print.PrintingPrefs" = {
      # Automatically quit printer app once the print jobs complete
      "Quit When Finished" = true;
    };
    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      # Check for software updates daily, not just once per week
      ScheduleFrequency = 1;
      # Download newly available updates in background
      AutomaticDownload = 1;
      # Install System data files & security updates
      CriticalUpdateInstall = 1;
    };
    # Stop nagging on new disks
    "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
    # Turn on app auto-update
    "com.apple.commerce".AutoUpdate = true;

    "com.apple.AdLib".allowApplePersonalizedAdvertising = false;

    # Prevent Photos from opening automatically when devices are plugged in
    "com.apple.ImageCapture".disableHotPlug = true;

    # JetDrive Toolbox
    "com.transcend.JetDriveToolbox-v2" = {
      # Disable auto update: use brew instead
      SUAutomaticallyUpdate = false;
      SUEnableAutomaticChecks = false;
      SUHasLaunchedBefore = true;
      # Accept EULA
      canEnterApp = true;
      # Disable analytics
      canSendGA = false;
    };
  };
}
