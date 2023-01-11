# dotfiles
![Coding should be fun!](https://media.giphy.com/media/ytwDCq9aT3cgEyyYVO/giphy-tumblr.gif "Coding should be fun!")

[@onnimonni](https://github.com/onnimonni) dotfiles. I'm full stack developer but I mainly work on devops and backend. These are my configs. This is personal backup for myself but hopefully you find it useful too. I deploy these with ansible so that I can have same configs in remote as locally.

Big thanks for [@anttiviljami](https://github.com/anttiviljami) for years of guidance.
I hope someday I will learn to play [vimgolf](http://www.vimgolf.com/) but until then I will need these cheats.

Many configs and aliases are copied from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles). Thank you guys for sharing these those!

## Includes
- Fish shell as default shell & plenty of noob friendly fish functions
- Custom nano keyboard mappings (I like `ctrl+c`, `ctrl+v` and `ctrl+f` a lot more than nano defaults)
- Monokai theme for terminal (but darker background for better contrast)

### Hardcore stuff which is probably useful only for me
- Custom keyboard mappings with [karabiner-elements](https://karabiner-elements.pqrs.org)
- This includes my own keyboard layout based on Dvorak ( I implemented small tweaks for finnish language ).

## Requirements
[rcm](https://github.com/thoughtbot/rcm)

## Installation on MacOS
```
$ git clone https://github.com/onnimonni/dotfiles ~/.dotfiles
$ bash ~/.dotfiles/.install.sh
```

# After installation config
1. Create new ssh key in Secretive
2. Copy the public key into `~/.ssh/secretive.pub`
3. Add it [into Github as new SSH key](https://github.com/settings/ssh/new) both as signing key and authentication key

## Recommended shell
Please try `fish` :)! It is much more pleasant than zsh.

## Recommended utilities

- **aspell** - for automatic spell checking in git commits
- **cowsay** - it makes ansible deployments much more funnier
- **wifi-password** - just type `wifi-password` if someone asks for it. Simple but convenient.
- **ansible** - For large remote deployments
- **docker** - Docker client to run docker locally (Choose from `docker-machine` and `dlite`)

## Recommended free applications
- **rectangle** - Really fancy open source window resizer with configurable hotkeys.
- **iterm2** - Better terminal than default.
- **karabiner-elements** - Custom keyboard mappings.

These all will be installed using `.install.sh`.

### Recommended free but not installed by default
- **evernote** - For your random thoughts and notes. Has really slick search and becames better more you use it!

## Recommended OS-X apps
- **Mail.app** - The default mail has been alright so far
- **Keychain Access.app** - For storing secrects like passwords and notes. Even works between iOS and OS-X devices.

## Recommended paid applications
**[copyclip2](https://fiplab.com/apps/copyclip-for-mac)** -
Saves ridiculous amount of hours and only costs **4.99$**.

## Update configs
```
# This only works in fish shell
$ update-dotfiles
```

## UNLICENSE
Use this package as you want to. Sharing is caring!
