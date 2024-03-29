#!/bin/bash

# Helper function
function command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Install homebrew which also installs macos commandline tools
if ! command_exists brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install utilities from Brewfile
brew bundle

# Install Copilot on cli
gh extension install github/gh-copilot

# Trust qlstephen
xattr -cr ~/Library/QuickLook/QLStephen.qlgenerator

# Install fish with homebrew
brew install fisher
# Enable fish for current user without asking password again
sudo chsh -s /opt/homebrew/bin/fish $USER

# Install z history helper
/opt/homebrew/bin/fish -c "fisher install jethrokuan/z"

# Install asdf helper
/opt/homebrew/bin/fish -c "fisher install rstacruz/fish-asdf"

# Activate dotfiles for the first time
rcup -d ~/.dotfiles -x UNLICENSE -x README.md

# Symlink whole karabiner folder from config
ln -sfn ~/.dotfiles/karabiner ~/.config/karabiner

##
# Install OnniDvorak custom keyboard layout
##
sudo cp ~/.dotfiles/init/onnimonni-Dvorak-QWERTY-CMD.keylayout /Library/Keyboard\ Layouts/

##
# MacOS Configs
##

# Make the spacing in the menu icons smaller so they don't hide under the notch
# Source: https://apple.stackexchange.com/a/465674/74811
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 6
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6

# Hide the dock by default and display it in snappy way
defaults write com.apple.dock "autohide" -bool "true"
defaults write com.apple.dock "autohide-delay" -float "0.1"
killall Dock

# Show hidden files in Finder
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
# Show list view of files
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"
killall Finder


##
# Betterzip Quicklook options
##
defaults write com.macitbetter.betterzip QLcD -bool true
defaults write com.macitbetter.betterzip QLcK -bool true
defaults write com.macitbetter.betterzip QLcP -bool true
defaults write com.macitbetter.betterzip QLcS -bool true

defaults write com.macitbetter.betterzip QLshowHiddenFiles -bool true
defaults write com.macitbetter.betterzip QLshowPackageContents -bool true
defaults write com.macitbetter.betterzip QLtarLimit -string "1024"

##
# CopyClip 2
##
# Use ⌘+⌥+space to activate the software
defaults write com.fiplab.copyclip2 HotKeyModifierKey -integer 1572864

##
# VSCode
##
# Install settings & keybindings
cp .vscode-config/*.json /Users/onnimonni/Library/Application\ Support/Code/User/

# Save screenshots to the desktop
mkdir "${HOME}/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Desktop/Screenshots"

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
echo "To enable login with gcloud you need to add the public files here:"
echo "$ ssh-add -L > .dotfiles/ssh/google_compute_engine.pub"
echo "And to login to GCP you need to"
echo "$ gcloud compute os-login ssh-keys add --key-file ~/.dotfiles/ssh/google_compute_engine.pub"

echo "Then run $ security find-generic-password -w -s 'CopyClip 2 License' -a 'onni@koodimonni.fi' and activate CopyClip"