#!/bin/zsh

# Stop on first error or ctrl+c
set -e
trap 'echo "\nCancelled."; exit 130' INT

# Accept Xcode license (needed before many dev tools work)
sudo xcodebuild -license accept

# Helper function
function command_exists () {
  command -v "$1" >/dev/null 2>&1
}

if softwareupdate -l 2>&1 | grep 'No new software available.' >/dev/null 2>&1; then
  echo "Skipping MacOS updates"
else
  echo "Installing MacOS updates requires sudo and restart"
  sudo softwareupdate --install --all --restart --verbose
fi

# Disable diagnostic reporting, i.e. telemetry
export NIX_INSTALLER_DIAGNOSTIC_ENDPOINT=""

# Install nix
if ! command_exists nix; then
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
fi

# Generate local-user.nix if it doesn't exist
if [ ! -f ~/.dotfiles/local-user.nix ]; then
  echo "Generating local-user.nix for this machine..."
  ~/.dotfiles/scripts/generate-local-user.sh
  # Add to git so nix flake can see it
  git -C ~/.dotfiles add local-user.nix
fi

# Bootstrap homebrew (nix-darwin takes over management after first switch)
if [ ! -x /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check App Store sign-in (needed for mas app installs)
if defaults read MobileMeAccounts Accounts 2>/dev/null | grep -q "AccountID"; then
  echo "App Store: signed in ✓"
else
  echo ""
  echo "=== App Store Setup ==="
  echo "Open App Store and sign in with your Apple ID before continuing."
  echo "Press Enter when you have signed in..."
  read -r
fi

# Setup MacOS with nix
# --inputs-from reuses the locked nix-darwin rev from flake.lock instead of
# fetching nix-darwin/master from GitHub (avoids API rate limits)
# --impure allows linux-builder.nix to check if builder was previously bootstrapped
# First run: linux builder disabled (flag file doesn't exist yet)
sudo /nix/var/nix/profiles/default/bin/nix run --inputs-from ~/.dotfiles nix-darwin#darwin-rebuild -- switch --impure --flake ~/.dotfiles/
# Second run: linux builder enabled (flag file created by first activation)
sudo /nix/var/nix/profiles/default/bin/nix run --inputs-from ~/.dotfiles nix-darwin#darwin-rebuild -- switch --impure --flake ~/.dotfiles/

# Launch Karabiner if not running (needed for keyboard remapping)
if ! pgrep -q karabiner_grabber; then
  echo "Starting Karabiner-Elements..."
  open -a "Karabiner-Elements"
fi

echo "INSTALLATION IS COMPLETE!"
echo ""
echo "OPTIONAL FINAL STEPS:"

echo "Then create a new ssh key named 'github-key' in Secretive and run:"
echo "$ ssh-add -L | grep github-key > ~/.ssh/github_secretive.pub"
echo "$ ssh-add -L > ~/.ssh/google_compute_engine.pub"
echo "$ ssh-add -L > ~/.ssh/secretive.pub"
echo "$ gh auth refresh -h github.com -s admin:public_key"
echo "$ gh ssh-key add ~/.ssh/secretive.pub"
echo "And to login to GCP you need to"
echo "$ gcloud compute os-login ssh-keys add --key-file ~/.ssh/google_compute_engine.pub"

echo "Maccy clipboard manager will be installed via brew and launched at login automatically"
