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

## To update Nix flake
I followed this tutorial to get started with [Nix on MacOS](https://nixcademy.com/posts/nix-on-macos/).
```
$ darwin-rebuild switch --flake .#simple
```

# After installation config
1. Create new ssh key in Secretive
2. Copy the public key into `~/.ssh/secretive.pub`
3. Add it [into Github as new SSH key](https://github.com/settings/ssh/new) both as signing key and authentication key

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
