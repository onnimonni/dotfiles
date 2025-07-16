{...}:
rec {
  homebrew.casks = [
    "finicky"
  ];

  # TODO: Don't hard code the username here
  home-manager.users.onnimonni.xdg.configFile = {
    # Force copy the file instead of symlinking
    "finicky.js" = {
      source = ./config/finicky.js;
      force = true;
      target = "../.finicky.js";
    };
  };
}
