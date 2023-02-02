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
brew install \
  rcm \    # To setup the dotfiles
  fish \   # The shell to replace zsh
  fisher \ # Install plugins to fish shell
  pwgen \  # To generate passwords
  asdf \   # Version manager for everything
  mas \    # Install applications from App Store with command line
  gh \     # Control Github with command line
  colima \ # Replaces Docker for Mac Desktop app
  docker \ # docker cli to interact with the docker
  docker-compose \ # this is not automatically installed with colima
  libpq  \  # psql client
  qlstephen \ # Quicklook tool to show contents of files without extension (eg README)
  betterzip # Zip utility which can show zip contents with quicklook (hitting spacebar in finder)

# Install few apps that are nice
brew install --cask \
    1password-cli \
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
    copyclip \
    lunar

# Install few software from Apple store as well
mas install 1365531024 # 1blocker 
# Trust qlstephen
xattr -cr ~/Library/QuickLook/QLStephen.qlgenerator

# Enable fish for current user without asking password again
sudo chsh -s /opt/homebrew/bin/fish $USER

# Install z history helper
/opt/homebrew/bin/fish -c "fisher install jethrokuan/z"

# Activate dotfiles for the first time
rcup -d ~/.dotfiles -x UNLICENSE -x README.md

# Install asdf plugins
for tool in nodejs python poetry terraform ruby elixir gcloud golang
    /opt/homebrew/bin/asdf plugin add $tool
end

# Symlink whole karabiner folder from config
ln -sfn ~/.dotfiles/karabiner ~/.config/karabiner

##
# Install OnniDvorak custom keyboard layout
##
sudo cp ~/.dotfiles/init/onnimonni-Dvorak-QWERTY-CMD.keylayout /Library/Keyboard\ Layouts/

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

echo "Then run $ security find-generic-password -w -s 'CopyClip 2 License' -a 'onni@koodimonni.fi' and activate CopyClip"