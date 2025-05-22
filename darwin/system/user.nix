{pkgs, ...}:
rec {
  system.primaryUser = "onnimonni";

  system.defaults.loginwindow.LoginwindowText = "Teretulemast ${system.primaryUser} 👋!";
  users.users."${system.primaryUser}" = {
    name = system.primaryUser;
    home = "/Users/${system.primaryUser}";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users."${system.primaryUser}" = { pkgs, ... }: {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
