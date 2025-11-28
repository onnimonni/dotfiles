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
# Install Xcode Command line tools to get git
$ xcode-select --install

# Clone the dotfiles and run the installation script
$ git clone https://github.com/onnimonni/dotfiles ~/.dotfiles

$ ~/.dotfiles/.install.sh
```

## To update everything
This command updates flake dependencies, nix, brew and duckdb extensions:
```
$ update-all
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

## Update configs from Github
```
# This only works in fish shell
$ update-dotfiles
```

## Common fixes
### warning: Nix search path entry
If you get following messages:
```
warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
```

You can fix them by running:
```sh
sudo nix-channel --update nixos
```

[Source](https://github.com/NixOS/nix/issues/2982#issuecomment-997983067)

### Karabiner is not working

Restart it by running ([source](https://karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/)):

```sh
launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server
```

## Docs for common procedures
* [Using Estonian ID-card as ssh public key](docs/estonian-id-card.md)

## UNLICENSE
Use these dotfiles as you want to. Sharing is caring!
