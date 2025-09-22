{ pkgs, ... }:
{
  users.users.onnimonni.shell = pkgs.fish;
  home-manager.users.onnimonni.programs.fish.enable = true;

  # FIXME: Fails often like this:
  # /nix/store/5kyj36g08zq4xi5311fww00b39jcb0bg-procps-1003.1-2008/bin/ps: illegal option -- -
  # Force fish for interactive sessions
  #programs.bash = {
  #  interactiveShellInit = ''
  #    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
  #    then
  #      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
  #      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
  #    fi
  #  '';
  #};

  # This disables annoying message when opening a new terminal:
  # Last login: Sun May 25 21:52:09 on ttys009
  home-manager.users.onnimonni.home.file = {
    ".hushlogin".text = ''
      # Disables last login from appearing in Terminal
    '';
  };

  # Also enable fish
  programs.fish = {
    enable = true;
    shellAliases = {
      # Update this config
      update-nix = "sudo darwin-rebuild switch --flake ~/.dotfiles/";

      update-all = ''
        nix flake update --flake ~/.dotfiles && \
        sudo darwin-rebuild switch --flake ~/.dotfiles/ && \
        duckdb -c "UPDATE EXTENSIONS;"
      '';

      # Reload fish config
      reload-fish = "source ~/.config/fish/config.fish";

      # Prevent overwriting or deleting by accident
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -iv";
    };
  };

  # FIXME: these don't seem to work for now :(
  environment.systemPackages = with pkgs; [
    fishPlugins.z
    fishPlugins.bang-bang
    # TODO fishPlugins.fzf-fish is not building because of weird issues
    # See more: https://github.com/NixOS/nixpkgs/issues/410069
    #fishPlugins.fzf-fish
    #fzf
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc
  ];
}
