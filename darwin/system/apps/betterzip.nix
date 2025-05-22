{...}:
rec {
  # Allows looking into zip file with MacOS QuickLook
  homebrew.casks = [
    "betterzip"
  ];

  system.defaults.CustomUserPreferences."com.macitbetter.betterzip" = {
    # Betterzip Quicklook options
    QLcD = true;
    QLcK = true;
    QLcP = true;
    QLcS = true;
    QLshowHiddenFiles = true;
    QLshowPackageContents = true;
    QLtarLimit = "1024";
  };
}
