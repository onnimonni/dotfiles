# Add aliases
### Added sublime editor as main editor
set SUBL "/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"

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


switch (uname)
case Darwin
  # Use Colima to run docker
  set -x DOCKER_HOST unix://$HOME/.colima/default/docker.sock
end