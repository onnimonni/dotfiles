{...}:
rec {
  # Allows looking into zip file with MacOS QuickLook
  homebrew.casks = [
    "iterm2"
  ];

  system.defaults.CustomUserPreferences."com.googlecode.iterm2" = {
    QuitWhenAllWindowsClosed = true;
    PromptOnQuit = false;

    # Allow system to restart/shutdown without prompting iterm
    NeverBlockSystemShutdown = true;

    SUEnableAutomaticChecks = false;
    SUHasLaunchedBefore = true;
    SUEnableAutomaticUpdates = false;

    # Annoying new feature to select the area for search
    ClickToSelectCommand = false;

    # Custom key bindings
    GlobalKeyMap = {
      # ⌥ + ⌫ to wipe a word
      "0x7f-0x80000-0x33" = {
          Action = 11;
          "Apply Mode" = 0;
          Escaping = 2;
          Text = "0x17";
          Version = 2;
      };
      # ⌥ + ⇧ + ⌫ to wipe a line
      "0x7f-0xa0000-0x33" = {
          Action = 11;
          "Apply Mode" = 0;
          Escaping = 2;
          Text = "0x15";
          Version = 2;
      };
    };
  };
}
