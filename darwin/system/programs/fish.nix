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
  #environment.systemPackages = with pkgs; [
  #  fishPlugins.z
  #  # bang-bang is missing from nix: https://github.com/NixOS/nixpkgs/issues/409901
  #  # fishPlugins.bang-bang
  #  # FIXME: Failing because of missing fishtape
  #  #fishPlugins.fzf-fish
  #  fishPlugins.forgit
  #  fishPlugins.hydro
  #  fzf
  #  fishPlugins.grc
  #  grc
  #];
}
