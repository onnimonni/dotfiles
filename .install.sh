#!/bin/zsh

# Stop on first error
set -e

# Helper function
function command_exists () {
  command -v "$1" >/dev/null 2>&1
}

if softwareupdate -l 2>&1 | grep 'No new software available.'
  echo "Skipping MacOS updates"
else
  echo "Installing MacOS updates requires sudo and restart"
  sudo softwareupdate --install --all --restart --verbose
end

# Install rosetta to be able to use and build intel binaries
softwareupdate --install-rosetta --agree-to-license

# Install homebrew which also installs macos commandline tools
if ! command_exists brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/onnimonni/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install nix
if ! command_exists nix; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

# Setup MacOS with nix
nix run nix-darwin -- switch --flake .


# Install utilities from Brewfile
export HOMEBREW_CASK_OPTS="--no-quarantine" # Disable gatekeeper popup for casks
brew bundle

# Install Copilot on cli
gh extension install github/gh-copilot

# Trust qlstephen
xattr -cr ~/Library/QuickLook/QLStephen.qlgenerator

# Enable fish for current user without asking password again
sudo chsh -s /opt/homebrew/bin/fish $USER

# Install fish plugins with fisher
for plugin in "jethrokuan/z" "lilyball/nix-env.fish" "oh-my-fish/plugin-bang-bang"
do
  /opt/homebrew/bin/fish -c "fisher install $plugin"
done

# Install mise auto completion
/opt/homebrew/bin/fish -c "mise use -g usage"

# Activate dotfiles for the first time
rcup -d ~/.dotfiles -x UNLICENSE -x README.md -x Brewfile

# Symlink whole karabiner folder from config
ln -sfn ~/.dotfiles/karabiner ~/.config/karabiner

##
# Install OnniDvorak custom keyboard layout
##
sudo cp ~/.dotfiles/init/*.keylayout /Library/Keyboard\ Layouts/

##
# MacOS Configs
##

# Show bluetooth settings in menubar to make it easier to connect to headphones
defaults -currentHost write com.apple.controlcenter.plist Bluetooth -int 18

# Source: https://macos-defaults.com/keyboard/applefnusagetype.html
# Don't do anything when pressing the fn/globe key
defaults write com.apple.HIToolbox AppleFnUsageType -bool false

# Disable "Do you want to enable Dication?" prompt after tapping ctrl or fn twice?
# https://apple.stackexchange.com/questions/365048/disable-dictation-from-command-line
defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool false

# Disable automatically unzipping zip files and opening downloaded files with safari
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Disable automatic period substitution by double-tapping space.
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

defaults write com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID -string "org.unknown.keylayout.ONNIDVORAK-QWERTYCMD"
defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 16383; "KeyboardLayout Name" = "ONNIDVORAK-QWERTYCMD"; }'

killall 'cfprefsd'

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
# Custom Keyboard shortcuts
##

# Source: https://github.com/krikchaip/dotfiles/blob/ffdb64222b6980a3c327084c6c21d59ddf25161b/home/.chezmoiscripts/run_onchange_system-settings.sh#L203
#** XML template for com.apple.symbolichotkeys -> AppleSymbolicHotKeys
function key-disable() {
  local TEMPLATE="<dict><key>enabled</key><false/></dict>"
  echo "$TEMPLATE"
}

#** XML template for com.apple.symbolichotkeys -> AppleSymbolicHotKeys
function key-combo() {
  local TEMPLATE="
    <dict>
      <key>enabled</key><true/>
      <key>value</key><dict>
        <key>type</key><string>standard</string>
        <key>parameters</key>
        <array>
          <integer>$1</integer>
          <integer>$2</integer>
          <integer>$3</integer>
        </array>
      </dict>
    </dict>
  "
  echo "$TEMPLATE"
}

#** Keyboard > Keyboard Shortcuts... > Keyboard > Move focus to next window = option + tab
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 "$(key-combo 65535 48 524288)"


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
# Vivid
##
defaults write com.goodsnooze.vivid SUHasLaunchedBefore -bool true
defaults write com.goodsnooze.vivid userHasValidLicense -bool true
defaults write com.goodsnooze.vivid SUAutomaticallyUpdate -bool true
defaults write com.goodsnooze.vivid SUEnableAutomaticChecks -bool true
defaults write com.goodsnooze.vivid seenOnboarding -bool true
defaults write com.goodsnooze.vivid seenV2Onboarding -bool true
defaults write com.goodsnooze.vivid launchType -string "Launch and Enable"
open -a "Vivid"

##
# VSCode
##
# Install settings & keybindings
cp .vscode-config/*.json /Users/onnimonni/Library/Application\ Support/Code/User/

# Open files with VSCode by default
for language in "ts" "js" "css" "svelte"
do
  echo duti -s com.microsoft.VSCode .$language all
done

# Save screenshots to the desktop
mkdir -p "${HOME}/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Desktop/Screenshots"

# This software needs to be open when the defaults are imported in the next steps
open -a Rectangle

# Import defaults settings from different software
# You can create these like this and then removing extra options
# defaults export com.fiplab.copyclip2 - > .dotfiles/.macos-defaults/com.fiplab.copyclip2.plist
for f in ~/.dotfiles/.macos-defaults/*.plist
do
 echo "Processing $f"
 filename=$(basename $f)
 config_name=$(basename $f .plist)

 # Import the configs into osx
 defaults import $config_name $filename
done

# Start the clipboard management software
open -a "CopyClip 2"

# Updates all values imported with defaults
# Source: https://apple.stackexchange.com/questions/201816/how-do-i-change-mission-control-shortcuts-from-the-command-line#comment653985_443412
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

open -a iTerm2
osascript <<EOD
tell application "iTerm"
    activate
    tell current window
        set newTab to (create tab with default profile command "cd ${HOME}/.dotfiles")
        tell current tab
            select
        end tell
        tell current session
            write text "# open Settings -> Keys -> Presets and import ${HOME}/.dotfiles/.macos-defaults/iterm2.itermkeymap"
        end tell
    end tell
end tell
EOD

echo "INSTALLATION IS COMPLETE!"
echo "OPTIONAL FINAL STEPS:"
echo "Activate onnimonni-Dvorak keyboard layout from"
echo "GO: System Preferences -> Keyboard \
-> Input Sources -> search 'onni' -> activate onnimonni-Dvorak"

echo "Then create a new ssh key in Secretive and add it to Github"
echo "To enable login with gcloud you need to add the public files here:"
echo "$ ssh-add -L > ~/.ssh/google_compute_engine.pub"
echo "$ ssh-add -L > ~/.ssh/secretive.pub"
echo "$ gh auth refresh -h github.com -s admin:public_key"
echo "$ gh ssh-key add ~/.ssh/secretive.pub"
echo "And to login to GCP you need to"
echo "$ gcloud compute os-login ssh-keys add --key-file ~/.ssh/google_compute_engine.pub"

echo "Then run $ security find-generic-password -w -s 'CopyClip 2 License' -a 'onni@koodimonni.fi' and activate CopyClip"