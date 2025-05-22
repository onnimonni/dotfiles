{...}:
rec {
  homebrew.casks = [
    "finicky"
  ];

  # TODO: Don't hard code the username here
  home-manager.users.onnimonni.home.file = {
    # Finicky can't use a symlink
    ".finicky.js".text = builtins.readFile ./config/finicky.js;
  };
}
