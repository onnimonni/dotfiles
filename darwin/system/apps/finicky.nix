{ username, ... }:
rec {
  homebrew.casks = [
    "finicky"
  ];

  home-manager.users.${username}.xdg.configFile = {
    # Force copy the file instead of symlinking
    "finicky.js" = {
      source = ./config/finicky.js;
      force = true;
      target = "../.finicky.js";
    };
  };
}
