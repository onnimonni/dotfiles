{pkgs, ...}:
rec {
  system.primaryUser = "onnimonni";

  system.defaults.loginwindow.LoginwindowText = "Teretulemast ${system.primaryUser} 👋!";
  users.users."${system.primaryUser}" = {
    name = system.primaryUser;
    home = "/Users/${system.primaryUser}";
    shell = pkgs.fish;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users."${system.primaryUser}" = { pkgs, ... }: {
    programs.fish.enable = true;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
