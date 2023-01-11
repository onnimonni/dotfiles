#!/bin/bash

# Helper function
function command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Install homebrew which also installs macos commandline tools
if ! command_exists brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install utilities
brew install rcm fish pwgen asdf mas gh

# Enable fish for current user without asking password again
sudo chsh -s /opt/homebrew/bin/fish $USER

# Activate dotfiles for the first time
rcup -d ~/.dotfiles -x UNLICENSE -x README.md

# Symlink whole karabiner folder from config
ln -sfn ~/.dotfiles/karabiner ~/.config/karabiner

# Install useful applications for developers using cask
brew install --cask 1password-cli \
                    google-chrome \
                    secretive \
                    visual-studio-code \
                    android-studio \
                    spotify \
                    vlc \
                    discord \
                    slack \
                    telegram \
                    whatsapp \
                    iterm2 \
                    finicky \
                    karabiner-elements \
                    typora \
                    rectangle \
                    maccy

# Install few software from Apple store as well
mas install 1365531024 # 1blocker 

##
# Install OnniDvorak custom keyboard layout
##
sudo cp ~/.dotfiles/init/onnimonni-Dvorak-QWERTY-CMD.keylayout /Library/Keyboard\ Layouts/

##
# Shell
##

# Enable fish
sudo chsh -s /opt/homebrew/bin/fish $USER

##
# Daemons
##

# Launch locate daemon
sudo launchtl load -w /System/Library/LaunchDaemons/com.apple.locate.plist


##
# MacOS Configs
##

# Hide the dock by default and display it in snappy way
defaults write com.apple.dock "autohide" -bool "true"
defaults write com.apple.dock "autohide-delay" -float "0.1"
killall Dock

# Show hidden files in Finder
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
# Show list view of files
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"
killall Finder

for f in ~/.dotfiles/.macos-defaults/*.plist
do
 echo "Processing $f"
 filename=$(basename $f)
 config_name=$(basename $f .plist)

 # Import the configs into osx
 defaults import $config_name $filename
done

# Updates all values imported with defaults
# Source: https://apple.stackexchange.com/questions/201816/how-do-i-change-mission-control-shortcuts-from-the-command-line#comment653985_443412
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "INSTALLATION IS COMPLETE!"
echo "OPTIONAL FINAL STEP:"
echo "Activate onnimonni-Dvorak keyboard layout from"
echo "GO: System Preferences -> Keyboard \
-> Input Sources -> search 'onni' -> activate onnimonni-Dvorak"

echo "Then create a new ssh key in Secretive and add it to Github"
