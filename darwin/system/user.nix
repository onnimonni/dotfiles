{ pkgs, username, ... }:
rec {
  system.primaryUser = username;

  system.defaults.loginwindow.LoginwindowText = "Teretulemast ${system.primaryUser} 👋!";
  users.users."${system.primaryUser}" = {
    name = system.primaryUser;
    home = "/Users/${system.primaryUser}";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users."${system.primaryUser}" =
    {
      config,
      pkgs,
      osConfig,
      ...
    }:
    {
      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "25.05";
      imports = [
        # Import the home-manager modules
        ./file-associations.nix
        ./keyboard.nix
      ];
    };
}
