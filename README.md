# dotfiles
![Coding should be fun!](https://media.giphy.com/media/ytwDCq9aT3cgEyyYVO/giphy-tumblr.gif "Coding should be fun!")

[@onnimonni](https://github.com/onnimonni) dotfiles. I'm full stack developer but I mainly work on devops and backend. These are my configs. This is personal backup for myself but hopefully you find it useful too. I deploy these with ansible so that I can have same configs in remote as locally.

Big thanks for [@anttiviljami](https://github.com/anttiviljami) for years of guidance.
I hope someday I will learn to play [vimgolf](http://www.vimgolf.com/) but until then I will need these cheats.

Many configs and aliases are copied from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles/) and [paulirish/dotfiles](https://github.com/paulirish/dotfiles). Thank you guys for sharing these those!

## Includes
- Fish shell as default shell & plenty of noob friendly fish functions
- Different fish configuration between local and remote shells (see [local.fish](config/fish/local.fish) & [remote.fish](config/fish/remote.fish))
- Automatically starts ssh agent when terminal is opened
- Automatic [rmate](https://github.com/aurora/rmate/blob/master/rmate) settings in order to use sublime text in remote servers.
- Automatic [english spell checking](git_template/hooks/prepare-commit-message) on git commits with [customizable word list](aspell.en.pws)
- Few [automatic syntax checks](git_template/hooks/pre-commit) on git commits (ruby,php,json)
- Custom nano keyboard mappings (I like `ctrl+c`, `ctrl+v` and `ctrl+f` a lot more than nano defaults)
- Monokai theme for terminal (but darker background for better contrast)

### Hardcore stuff which is probably useful only for me
- Custom keyboard mappings with [seil](https://pqrs.org/osx/karabiner/seil.html.en) and [karabiner](https://pqrs.org/osx/karabiner/)
- This includes my own keyboard layout based on Dvorak ( I implemented small tweaks for finnish language ).

## Requirements
[rcm](https://github.com/thoughtbot/rcm)

## Installation on OSX
```
$ brew tap thoughtbot/formulae
$ brew install rcm
$ rcup -d ~/.dotfiles -x LICENSE -x README.md -x ssh
```

## Recommended shell
Please try `fish` :)! It is much more pleasant than bash.

## Recommended utilities

- **aspell** - for automatic spell checking in git commits
- **cowsay** - it makes ansible deployments much more funnier
- **wifi-password** - just type `wifi-password` if someone asks for it. Simple but convenient.
- **ansible** - For large remote deployments
- **docker** - Docker client to run docker locally (Choose from `docker-machine` and `dlite`)

## Recommended free applications
- **spectacle** - Really fancy open source window resizer with configurable hotkeys.
- **iterm2** - Better terminal than default.
- **karabiner** - Custom keyboard mappings.
- **seil** - Override system keys into whatever you want to.
- **slack** - Slack is simple but configurable chat for organisations.
- **vagrant** - Really easy virtual machine configuration.
- **virtualbox** - Virtual machine engine for vagrant.
- **skype** - Usually people use this for video meetings. I like google hangouts but skype has more users.
- **gpgtools** - Please start using OpenPGP as soon as you can. Emails are not so secure as you think. This works well with OS-X mail.app.
- **vlc** - For playing whatever videos you want to. VLC can handle them all.

These all will be installed using `.install.sh`.

### Recommended free but not installed by default
- **evernote** - For your random thoughts and notes. Has really slick search and becames better more you use it!

## Recommended OS-X apps
- **Mail.app** - Only one which works well with gpg. I miss mailbox for UI.
- **Keychain Access.app** - For storing secrects like passwords and notes. Even works between iOS and OS-X devices.

## Recommended paid applications
**[copyclip2](https://fiplab.com/apps/copyclip-for-mac)** -
Saves ridiculous amount of hours and only costs **4.99$**.

**[sublime text 3](https://www.sublimetext.com/buy)** - My preferred text editor costs hefty **70$** but is so awesome I could not work without it.

I think you can use **[atom by github](https://atom.io/)** too.
Sublime just has a lot faster search algorithm than atom (according to my subjective testing).

**[RescueTime Premium](https://www.rescuetime.com/)** - Rescuetime saves a lot time. It automatically produces reports for you about your computer usage patterns. I'm really lousy in tracking hours so this is priceless. **$72/year**

## Installation
```
$ git clone https://github.com/onnimonni/dotfiles ~/.dotfiles
$ rcup -d ~/.dotfiles -x UNLICENSE -x README.md
```

### Install all settings and utilities in OS-X
```
# Installs utilities and additional settings
$ bash ~/.dotfiles/.install.sh

# Installs os-x sensible defaults from mathiasbynens/dotfiles
$ bash ~/.dotfiles/osx
```

## Update configs
```
# This only works in fish shell
$ update-dotfiles
```

## UNLICENSE
Use this package as you want to. Sharing is caring!
