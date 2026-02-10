#!/bin/zsh

# Stop on first error
set -e

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
softwareupdate --install-rosetta --agree-to-license

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
fi

# Setup MacOS with nix (--impure needed to read gitignored local-user.nix)
sudo nix run --impure nix-darwin/master#darwin-rebuild -- switch --impure --flake ~/.dotfiles/

echo "INSTALLATION IS COMPLETE!"
echo "Visit: https://flakehub.com/token/create?class=user and create new token"
echo "then run this command and paste your token there:"
echo "$ determinate-nixd login"
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
