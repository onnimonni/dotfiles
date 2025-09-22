{...}:
{
  homebrew.taps = [
    "onnimonni/tap"
  ];

  # These need to be installed in this order:
  # See more in: https://github.com/onnimonni/homebrew-tap
  homebrew.casks = [
    "wine-stable"
    "ftdi-vcp-driver"
    "forscan"
  ];

  # Forscan can't be installed if "wine-stable" is quarantined
  homebrew.caskArgs.no_quarantine = true;
}
