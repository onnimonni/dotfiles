{ username, ... }:
rec {
  # Allows looking into zip file with MacOS QuickLook
  homebrew.casks = [
    "iterm2"
  ];

  # Deploy iTerm2 dynamic profile with fish shell and color theme
  home-manager.users.${username}.home.file."Library/Application Support/iTerm2/DynamicProfiles/dotfiles-profile.json".source =
    ./config/iterm2-profile.json;

  system.defaults.CustomUserPreferences."com.googlecode.iterm2" = {
    QuitWhenAllWindowsClosed = true;
    PromptOnQuit = false;

    # Allow system to restart/shutdown without prompting iterm
    NeverBlockSystemShutdown = true;

    SUEnableAutomaticChecks = false;
    SUHasLaunchedBefore = true;
    SUEnableAutomaticUpdates = false;

    # Allow clicking multiline URLs from terminal
    IgnoreHardNewlinesInURLs = true;

    # Annoying new feature to select the area for search
    ClickToSelectCommand = false;

    # Custom key bindings
    # To update these you need to first create them in iTerm2 UI and then read them with:
    # $ defaults read com.googlecode.iterm2 GlobalKeyMap
    GlobalKeyMap = {
      # Because I'm using custom Dvorak there's 'j' character in place of 'c'
      # Sometimes my qwerty muscle memory still kicks in so when pressing physical c button
      # ^ + j to terminate the process
      "0x6a-0x40000-0x8" = {
        Action = 11;
        "Apply Mode" = 0;
        Escaping = 2;
        Text = "0x03";
        Version = 2;
      };
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
      # ⌘ + ← to jump to start of the line
      "0xf702-0x300000-0x7b" = {
        Action = 11;
        "Apply Mode" = 0;
        Escaping = 2;
        Text = "0x01";
        Version = 2;
      };
      # ⌘ + → to jump to end of the line
      "0xf703-0x300000-0x7c" = {
        Action = 11;
        "Apply Mode" = 0;
        Escaping = 2;
        Text = "0x05";
        Version = 2;
      };
    };
  };
}
