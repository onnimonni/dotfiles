##
# Start or re-use a gpg-agent.
##
#
# Assumes gpg-agent writes its environment info in ~/.gpg-agent-info.
#
# Sets the gpg-agent environment stuff as universal variables, so it
# takes effect across all shells.

function __refresh_gpg_agent_info -d "Re-load ~/.gpg-agent-info into environment"
  cat ~/.gpg-agent-info | sed 's/=/ /' | while read key value
    set -e $key
    set -U -x $key "$value"
  end
end

if not set -q -x GPG_AGENT_INFO
  gpg-agent --daemon >/dev/null
end

if test -f ~/.gpg-agent-info
  __refresh_gpg_agent_info

  gpg-connect-agent /bye ^/dev/null
  if test $status -eq 1
    pkill -U $USER gpg-agent
    gpg-agent --daemon >/dev/null
    __refresh_gpg_agent_info
  end
end

# Use rbenv
if type -q rbenv
  status --is-interactive; and source (rbenv init -|psub)
end

# Set Path for Golang
set -x GOPATH "$HOME/go"
set -x GOBIN "$GOPATH/bin"
set -x PATH $PATH $GOBIN

# Set LD path for gpg2
set -x LD_LIBRARY_PATH /usr/local/lib

# Add aliases
### Added sublime editor as main editor
set SUBL "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"

### Sometimes I mistake if I'm in remote or not
alias rmate '/usr/local/bin/subl'

### Todo.txt
alias t todo.sh

# Set default editor
set -U EDITOR "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n -w"
set -U KUBE_EDITOR "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n -w"
set -U VISUAL "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n -w"
set -U HOMEBREW_EDITOR "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl -n -w"

# Shortcuts
alias d "cd ~/Documents/Dropbox"
alias dl "cd ~/Downloads"
alias dt "cd ~/Desktop"
alias p "cd ~/Projects"

alias wpscan "docker run --rm wpscanteam/wpscan"

# Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple’s System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash "sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update 'sudo softwareupdate -i -a; brew update; brew upgrade --all; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update'

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill "ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Trim new lines and copy to clipboard
alias cb "tr -d '\n' | pbcopy"

##
# Change to current finder folder
##
function cdf --description 'Change to directory which is open in Finder'
  if [ -x /usr/bin/osascript ]
    set -l target (osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)')
    if [ "$target" != "" ]
      cd "$target"; pwd
    else
      echo 'No Finder window found' >&2
    end
  end
end


##
# cd to current finder folder (inverse of cdf)
##
function fdc --description 'Change Finder to current directory'
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
end

##
# Add more words to spell checking
##
function edit-spelling --description "Edit aspell current dictionary"
  edit ~/.aspell.en.pws
end

# Add to spell checking word list
function add-spelling --description 'Adds words into aspell spell check dictionary'
  for arg in $argv
      echo $arg >> ~/.dotfiles/aspell.en.pws
  end

  # Move temporarely
  /bin/mv ~/.dotfiles/aspell.en.pws ~/.dotfiles/aspell.en.pws.bak

  # Remove duplicates from dictionary
  head -n 1 ~/.dotfiles/aspell.en.pws.bak >> ~/.dotfiles/aspell.en.pws
  tail -n +2 ~/.dotfiles/aspell.en.pws.bak | sort | uniq -i >> ~/.dotfiles/aspell.en.pws

  # Remove temporary file
  rm -f ~/.dotfiles/aspell.en.pws.bak > /dev/null

  # Immediately save them in git
  set -lx DDIR $HOME/.dotfiles/
  git --git-dir=$DDIR/.git --work-tree=$DDIR \
      commit aspell.en.pws -m "Added words: '$argv' to spell checking"
end
