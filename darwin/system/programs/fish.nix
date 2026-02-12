{ pkgs, username, ... }:
{
  users.users.${username}.shell = pkgs.fish;

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
  home-manager.users.${username} = {
    home.file = {
      ".hushlogin".text = ''
        # Disables last login from appearing in Terminal
      '';

      # Ghostty terminal config
      ".config/ghostty/config".text = ''
        command = ${pkgs.fish}/bin/fish

        font-family = JetBrains Mono
        font-size = 14

        window-padding-x = 8
        window-padding-y = 8
        macos-titlebar-style = hidden

        theme = light:dotfiles-light,dark:dotfiles-dark
        cursor-style-blink = false
        confirm-close-surface = false
        scrollback-limit = 1000
        mouse-hide-while-typing = true
      '';

      # Ghostty light theme (extracted from iTerm2 profile)
      ".config/ghostty/themes/dotfiles-light".text = ''
        palette = 0=#14191e
        palette = 1=#b43c2a
        palette = 2=#00c200
        palette = 3=#c7c400
        palette = 4=#2744c8
        palette = 5=#c040be
        palette = 6=#00c5c7
        palette = 7=#c7c7c7
        palette = 8=#686868
        palette = 9=#dd7975
        palette = 10=#58e790
        palette = 11=#ece100
        palette = 12=#a7abf2
        palette = 13=#e17ee1
        palette = 14=#60fdff
        palette = 15=#ffffff
        background = #fafafa
        foreground = #101010
        cursor-color = #000000
        cursor-text = #ffffff
        selection-background = #b3d7ff
        selection-foreground = #000000
      '';

      # Ghostty dark theme (extracted from iTerm2 profile)
      ".config/ghostty/themes/dotfiles-dark".text = ''
        palette = 0=#14191e
        palette = 1=#b43c2a
        palette = 2=#00c200
        palette = 3=#c7c400
        palette = 4=#2744c8
        palette = 5=#c040be
        palette = 6=#00c5c7
        palette = 7=#c7c7c7
        palette = 8=#686868
        palette = 9=#dd7975
        palette = 10=#58e790
        palette = 11=#ece100
        palette = 12=#a7abf2
        palette = 13=#e17ee1
        palette = 14=#60fdff
        palette = 15=#ffffff
        background = #15191f
        foreground = #dcdcdc
        cursor-color = #ffffff
        cursor-text = #000000
        selection-background = #b3d7ff
        selection-foreground = #000000
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

        # Free up disk space
        free-up-disk = "brew cleanup --prune=all && container prune && nix-collect-garbage -d && xcrun simctl delete unavailable && sudo rm -rf ~/.Trash/*";

        # Prevent overwriting or deleting by accident
        mv = "mv -iv";
        rm = "rm -iv";

        # Directory shortcuts
        d = "cd ~/Downloads";
        dt = "cd ~/Desktop";
        p = "cd ~/Projects";

        # Use container instead of docker
        docker = "container";
        docker-compose = "container compose";
        wpscan = "container run --rm wpscanteam/wpscan";

        # Empty the Trash on all mounted volumes and the main HDD.
        # Also, clear Apple's System Logs to improve shell startup speed.
        # Finally, clear download history from quarantine. https://mths.be/bum
        emptytrash = "sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'";

        # Kill all the tabs in Chrome to free up memory
        # [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
        chromekill = "ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill";

        # Trim new lines and copy to clipboard
        cb = "tr -d '\\n' | pbcopy";

        # Open files with specific apps
        antigravity = "open -a /Applications/Antigravity.app";
        vlc = "open -a /Applications/VLC.app";
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

        # Opt out of query.farm telemetry (DuckDB extension)
        set -gx QUERY_FARM_TELEMETRY_OPT_OUT true

        # Number of CPU cores for devenv/build tools
        set -gx DEVENV_CORES (sysctl -n hw.ncpu)

        # Load secrets file if it exists
        if test -f ~/.secrets.fish
          source ~/.secrets.fish
        end
      '';

      functions = {
        cpg = {
          description = "Copy directory excluding .gitignore'd files";
          body = ''
            if test (count $argv) -ne 2
              echo "Usage: cpg <src> <dest>" >&2
              return 1
            end
            rsync -a --filter=':- .gitignore' --exclude='.git' $argv[1]/ $argv[2]/
          '';
        };

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

        typora = {
          description = "Create/open file in Typora";
          body = ''
            if test (count $argv) -eq 0
              echo "Usage: typora <filename>" >&2
              return 1
            end
            touch $argv[1]
            open -a "Typora.app" $argv[1]
          '';
        };

        cp = {
          description = "Copy file to clipboard (1 arg) or cp -iv (2+ args)";
          wraps = "cp";
          body = ''
            if contains -- --help $argv; or contains -- -h $argv
              echo "Usage: cp <file>          - copy file to macOS clipboard"
              echo "       cp <src> <dest>    - cp -iv (safe copy)"
              echo ""
              echo "With one argument: copies the file to the clipboard so you"
              echo "can paste it in Finder (Cmd+V) or terminal (Cmd+V as path)."
              echo "With two or more arguments: runs 'cp -iv'."
              return 0
            end
            if test (count $argv) -eq 1 && not string match -q -- '-*' $argv[1]
              set -l abs_path (realpath $argv[1])
              osascript -l JavaScript -e '
              function run(argv) {
                ObjC.import("AppKit");
                var path = argv[0];
                var pb = $.NSPasteboard.generalPasteboard;
                pb.clearContents;
                pb.setPropertyListForType([path], "NSFilenamesPboardType");
                pb.setStringForType(path, "public.utf8-plain-text");
              }' "$abs_path"
            else
              command cp -iv $argv
            end
          '';
        };

        aws-exec = {
          description = "Run command with AWS credentials from SSO/login";
          body = ''
            # Check if -- separator and command provided
            set -l cmd_start 0
            for i in (seq (count $argv))
                if test "$argv[$i]" = "--"
                    set cmd_start (math $i + 1)
                    break
                end
            end

            if test $cmd_start -eq 0 -o $cmd_start -gt (count $argv)
                echo "Usage: aws-exec -- command [args...]" >&2
                return 1
            end

            # Check if logged in to AWS
            if not aws sts get-caller-identity > /dev/null 2>&1
                echo "Error: AWS not logged in or credentials expired" >&2
                echo "Run 'aws login' to authenticate" >&2
                return 1
            end

            # Get credentials with proper quoting and run command
            set -l env_vars (aws configure export-credentials --format env-no-export | sed 's/=\(.*\)/="\1"/')
            eval $env_vars $argv[$cmd_start..-1]
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
