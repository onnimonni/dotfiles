{ pkgs, ... }:
{
  users.users.onnimonni.shell = pkgs.fish;

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
  home-manager.users.onnimonni = {
    home.file = {
      ".hushlogin".text = ''
        # Disables last login from appearing in Terminal
      '';
    };

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

        # Directory shortcuts
        d = "cd ~/Downloads";
        dt = "cd ~/Desktop";
        p = "cd ~/Projects";

        # Docker wpscan
        wpscan = "docker run --rm wpscanteam/wpscan";

        # Empty the Trash on all mounted volumes and the main HDD.
        # Also, clear Apple's System Logs to improve shell startup speed.
        # Finally, clear download history from quarantine. https://mths.be/bum
        emptytrash = "sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'";

        # Kill all the tabs in Chrome to free up memory
        # [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
        chromekill = "ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill";

        # Trim new lines and copy to clipboard
        cb = "tr -d '\\n' | pbcopy";
      };

      shellInit = ''
        # Set default editor
        set -U EDITOR "code"
        set -U KUBE_EDITOR "$EDITOR --wait"
        set -U VISUAL $EDITOR
        set -U HOMEBREW_EDITOR $EDITOR

        # Some builds in MacOs seem to need this
        # Source: https://github.com/smashedtoatoms/asdf-postgres
        set -Ux HOMEBREW_PREFIX (brew --prefix)
        set -Ux HOMEBREW_CASK_OPTS "--no-quarantine" # Don't quarantine casks by default

        # Use Colima to run docker on Darwin
        switch (uname)
          case Darwin
            set -x DOCKER_HOST unix://$HOME/.colima/default/docker.sock
        end

        # Load secrets file if it exists
        if test -f ~/.secrets.fish
          source ~/.secrets.fish
        end
      '';

      functions = {
        update-to-latest = {
          description = "Updates MacOS, Homebrew & asdf";
          body = ''
            echo "Checking MacOS updates first"
            # Update MacOS
            if softwareupdate -l 2>&1 | grep 'No new software available.'
              echo "Skipping MacOS updates"
            else
              echo "Installing MacOS updates requires sudo and restart"
              sudo softwareupdate --install --all --restart --verbose
            end

            # Homebrew installed stuff
            echo "brew update"
            brew update
            echo "brew upgrade --no-quarantine # Heroic needs the no-quarantine"
            brew upgrade --no-quarantine

            # Mise (asdf clone) plugins
            echo "mise (asdf clone) upgrade"
            mise upgrade
          '';
        };

        cdf = {
          description = "Change to directory which is open in Finder";
          body = ''
            if [ -x /usr/bin/osascript ]
              set -l target (osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)')
              if [ "$target" != "" ]
                cd "$target"; pwd
              else
                echo 'No Finder window found' >&2
              end
            end
          '';
        };

        gemini-cli-help = {
          description = "Query Gemini for CLI help";
          body = ''
            set -l model "gemini-2.0-flash"
            set -l response (http --json "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY" \
              contents[][parts][][text]="Answer shortly without markdown syntax. Give me a command I can run directly in the MacOS fish terminal to accomplish the following: '$argv'")
            set -l command (echo $response | jq -r '.candidates[0].content.parts[0].text')
            echo "Use this command from your clipboard:"
            echo "\$ $command"
            echo $command | tr -d '\n' | pbcopy
          '';
        };

        gemini-help = {
          description = "Query Gemini for any help";
          body = ''
            set -l model "gemini-2.0-flash"
            set -l response (http --json "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY" \
              contents[][parts][][text]="Answer shortly without markdown syntax. $argv")
            set -l command (echo $response | jq -r '.candidates[0].content.parts[0].text')
            echo $command
          '';
        };

        wait-port-open = {
          description = "Wait for port to open";
          body = ''
            while not echo '{"hostUp": true}' | nc -w 10 $argv > /dev/null
                sleep 1
            end
          '';
        };

        fdc = {
          description = "Change Finder to current directory";
          body = ''
            if [ -x /usr/bin/osascript ]

              set -lx first_char (echo $argv | cut -c 1)
              if [ "$first_char" != "" ]
                set thePath (pwd)
              else if [ "$first_char" != "/" ]
                set thePath (pwd)/"$argv"
              else
                set thePath "$argv"
              end
              osascript -e 'set myPath to ( POSIX file "'$thePath'" as alias )
              try
                tell application "Finder" to set the (folder of the front window) to myPath
              on error -- no open folder windows
                tell application "Finder" to open myPath
              end try
              tell application "Finder" to activate'
            end
          '';
        };
      };
    };
  };

  # Also enable fish at system level
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
