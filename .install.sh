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

# Install nix
if ! command_exists nix; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# Remove the default file so that nix-core.nix is able to write custom nix config there
sudo rm /etc/nix/nix.custom.conf

# Setup MacOS with nix
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.dotfiles/

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
