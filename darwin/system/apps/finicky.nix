{...}:
rec {
  homebrew.casks = [
    "finicky"
  ];

  # TODO: Don't hard code the username here
  home-manager.users.onnimonni.home.file = {
    ".finicky.js".source = ./config/finicky.js;
  };
}
