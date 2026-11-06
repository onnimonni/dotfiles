{ username, ... }:
{
  homebrew.casks = [
    "finicky"
  ];

  home-manager.users.${username} = {
    # Open links in Finicky
    urlHandlers."se.johnste.finicky" = [
      "http"
      # duti alias for "default web browser"
      "com.apple.default-app.web-browser"
    ];

    xdg.configFile = {
      # Force copy the file instead of symlinking
      "finicky.js" = {
        source = ./config/finicky.js;
        force = true;
        target = "../.finicky.js";
      };
    };
  };
}
