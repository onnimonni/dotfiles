#!/bin/bash

# Helper function
function command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Ask for sudo only once
echo "Enter your sudo password for one time. This is for installing pip."
sudo -v

# Install homebrew which also installs macos commandline tools
if ! command_exists brew; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install utilities
brew tap thoughtbot/formulae
brew install rcm aspell wifi-password fish node gpg2 thefuck cowsay pwgen # Last one is must have

# Activate dotfiles for the first time
rcup -d ~/.dotfiles -x UNLICENSE -x README.md -x osx -x plist -x init -x karabiner

# Symlink whole karabiner folder from config
ln -sfn ~/.dotfiles/karabiner ~/.config/karabiner

# Install PHP7.1 and composer
brew tap homebrew/homebrew-php
brew install php71
brew install composer

# Install miscellaneous helpers
brew install hub awscli terraform

# Replace OSX utilities with newer ones
brew install openssh --with-keychain-support

# Install pygmentize and ansible through pip
sudo easy_install pip
sudo pip install pygments ansible --upgrade --ignore-installed six

# Install travis gem for .travis.yml syntax checking
gem install travis --no-rdoc --no-ri

# Install useful applications for developers using cask
brew cask install google-chrome firefox \
                  iterm2 virtualbox gpgtools vagrant vagrant-manager \
                  docker \
                  slack skype hipchat telegram \
                  vlc \
                  karabiner-elements spectacle flux \
                  keybase

##
# Activate Karabiner-Elements settings
# These will allow you to move with arrow keys using fn+wasd or fn+ijkl
# These will also allow to enter number with homerow space+{asdfghjkl}
##

# Install custom karabiner settings from the dotfiles repository
if [ -f ~/.dotfiles/karabiner/elements.json ]; then
	open karabiner://karabiner/assets/complex_modifications/import?url=file%3A%2F%2F%2FUsers%2F$USER%2F.dotfiles%2Fkarabiner%2Felements.json
fi

##
# Install OnniDvorak-QWERTY-CMD custom keyboard layout
##
sudo cp ~/.dotfiles/init/onnimonni-Dvorak-QWERTY-CMD /Library/Keyboard\ Layouts/
sudo cp ~/.dotfiles/init/onnimonni-Dvorak-QWERTY-CMD.keylayout /Library/Keyboard\ Layouts/

##
# Miscellaneous
##

# Create the custom folder for golang binaries
mkdir -p ~/go/bin

# Create folder for todo.txt
mkdir -p ~/todo

##
# Shell
##

# This adds /usr/local/bin/fish to shell options
grep -q -F "/usr/local/bin/fish" /etc/shells || echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
# Enable fish
chsh -s /usr/local/bin/fish

##
# Daemons
##

# Launch locate daemon
sudo launchtl load -w /System/Library/LaunchDaemons/com.apple.locate.plist


##
# MacOS Configs
##
for f in ~/.dotfiles/.osx-defaults/*.plist
do
 echo "Processing $f"
 filename=$(basename $f)
 config_name=$(basename $f .plist)

 # Import the configs into osx
 defaults import $config_name $filename
done


echo "INSTALLATION IS COMPLETE!"
echo "OPTIONAL FINAL STEP:"
echo "Activate onnimonni-Dvorak keyboard layout from"
echo "GO: System Preferences -> Keyboard \
-> Input Sources -> search 'onni' -> activate onnimonni-Dvorak"
