# dotfiles
![Coding should be fun!](https://media.giphy.com/media/ytwDCq9aT3cgEyyYVO/giphy-tumblr.gif "Coding should be fun!")

[@onnimonni](https://github.com/onnimonni) dotfiles. I'm full stack developer but I mainly work on devops and backend. These are my configs. This is personal backup for myself but hopefully you find it useful too.

Big thanks for [@anttiviljami](https://github.com/anttiviljami) for years of guidance.
I hope someday I will learn to play [vimgolf](http://www.vimgolf.com/) but until then I will need these cheats.

### Stuff which is probably useful only for me
- Custom keyboard mappings with [karabiner-elements](https://karabiner-elements.pqrs.org)
- This includes my own keyboard layout based on Dvorak ( I implemented small tweaks for finnish language ).

## Installation on fresh MacOS
```
# Ensure that you run the latest MacOS available
$ softwareupdate -l 2>&1 | grep 'No new software available.' || sudo softwareupdate --install --all --restart --verbose

# Install Xcode Command line tools to get git
$ xcode-select --install

# Clone the dotfiles and run the installation script
$ git clone https://github.com/onnimonni/dotfiles ~/.dotfiles

$ ~/.dotfiles/.install.sh
```

## Initial installation
You need to uncomment `{ nix.linux-builder.enable = true; }` and comment `nix-rosetta-builder.darwinModules.default` and run the:
```
$ darwin-rebuild switch --flake .
```

Then toggle the comments in the code above and build again. This will allow your Apple Silicon laptop to build to linux-x86-64 targets.

## To update Nix flake
I followed this tutorial to get started with [Nix on MacOS](https://nixcademy.com/posts/nix-on-macos/).
```
$ darwin-rebuild switch --flake .
```

### Setup UTM so that Mac can build x86_64-linux servers
Download latest NixOS Minimal ISO for 64-bit ARM:
```
cd ~/Downloads
# This version might have changed
curl -O https://channels.nixos.org/nixos-24.05/latest-nixos-minimal-aarch64-linux.iso
```
Then open the UTM and launch the new VM
Start -> Virtualize -> Linux

Then select:
[x] Use Apple Virtualization
[x] Enable Rosetta (x86_64 Emulation)

And select your Boot ISO image which you downloaded earlier and start the VM.

First in the VM run:
```sh
$ sudo su
$ passwd
# type 'root' as password
$ ip -4 addr show
# Copy the ipv4 address so that you can then continue on the host machine terminal
```
On host machine
```sh
# Install your ssh keys into the VM
$ ssh-copy-id root@<ipv4-addr-here>
```

# After installation config
1. Create new ssh key in Secretive
2. Copy the public key into `~/.ssh/secretive.pub`
3. Add it [into Github as new SSH key](https://github.com/settings/ssh/new) both as signing key and authentication key

## Add API key for Gemini
You can create a new API key to use Gemini from command line here: https://aistudio.google.com/app/apikey

```sh
echo 'export GEMINI_API_KEY="XXXXXX"' >> ~/.secrets.fish
```

## Update configs
```
# This only works in fish shell
$ update-dotfiles
```

## Update the latest brew installations from homebrow to Brewfile
```
$ cd ~/.dotfiles
$ brew bundle dump --force
```

## UNLICENSE
Use these dotfiles as you want to. Sharing is caring!
