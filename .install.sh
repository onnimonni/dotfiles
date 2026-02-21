#!/bin/zsh

# Stop on first error or ctrl+c
set -e
trap 'echo "\nCancelled."; exit 130' INT

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

# Install rosetta to be able to use and build intel binaries
if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
  echo "Rosetta 2 already installed. Skipping..."
else
  softwareupdate --install-rosetta --agree-to-license
fi

# Disable diagnostic reporting, i.e. telemetry
export NIX_INSTALLER_DIAGNOSTIC_ENDPOINT=""

# Install nix
if ! command_exists nix; then
  # Disable the determinate nix because the linux builder was not that useful in the end
  #curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
fi

# Remove the default file so that nix-core.nix is able to write custom nix config there
sudo rm -f /etc/nix/nix.custom.conf

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

# Sign into App Store before nix-darwin (needed for mas app installs)
echo ""
echo "=== App Store Setup ==="
echo "Open App Store and sign in with your Apple ID before continuing."
echo "Press Enter when you have signed in..."
read -r

# Setup MacOS with nix
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.dotfiles/

echo "INSTALLATION IS COMPLETE!"
echo "Visit: https://flakehub.com/token/create?class=user and create new token"
echo "then run this command and paste your token there:"
echo "$ determinate-nixd login"
echo "OPTIONAL FINAL STEPS:"
echo "Activate onnimonni-Dvorak keyboard layout from"
echo "GO: System Preferences -> Keyboard \
-> Input Sources -> search 'onni' -> activate onnimonni-Dvorak"

echo "Then create a new ssh key named 'github-key' in Secretive and run:"
echo "$ ssh-add -L | grep github-key > ~/.ssh/github_secretive.pub"
echo "$ ssh-add -L > ~/.ssh/google_compute_engine.pub"
echo "$ ssh-add -L > ~/.ssh/secretive.pub"
echo "$ gh auth refresh -h github.com -s admin:public_key"
echo "$ gh ssh-key add ~/.ssh/secretive.pub"
echo "And to login to GCP you need to"
echo "$ gcloud compute os-login ssh-keys add --key-file ~/.ssh/google_compute_engine.pub"

echo "Maccy clipboard manager will be installed via brew and launched at login automatically"
