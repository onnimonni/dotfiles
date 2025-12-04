{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Node
    nodejs
    pnpm
  ];

  # Set XDG_CONFIG_HOME for pnpm and other tools
  # Without this the config files are in ~/Library/Preferences/pnpm/rc
  environment.variables.XDG_CONFIG_HOME = "~/.config/";

  # Prevent Shai Hulud kind of worms
  # https://news.ycombinator.com/item?id=46035533
  home-manager.users.onnimonni.home.file = {
    # Even if files have .zip extension they are sometimes gunzipped
    ".yarnrc".text = ''
      ignore-scripts true
    '';
    ".npmrc".text = ''
      ignore-scripts true
    '';
    ".config/pnpm/rc".text = ''
      ignore-scripts=true
    '';
  };
}
