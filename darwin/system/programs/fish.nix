{ pkgs, ... }:
{
  users.users.onnimonni.shell = pkgs.fish;
  programs.fish.enable = true;
  home-manager.users.onnimonni.programs.fish.enable = true;

  # Force fish for interactive sessions
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # FIXME: these don't seem to work for now :(
  environment.systemPackages = with pkgs; [
    fishPlugins.z
    fishPlugins.bang-bang
    # Add this manually before building fzf-fish if needed
    # See more: https://github.com/NixOS/nixpkgs/issues/410069
    #fishPlugins.fishtape
    fishPlugins.fzf-fish
    fzf
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc
  ];
}
