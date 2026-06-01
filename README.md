# dotfiles
![Coding should be fun!](https://media.giphy.com/media/ytwDCq9aT3cgEyyYVO/giphy-tumblr.gif "Coding should be fun!")

[@onnimonni](https://github.com/onnimonni) dotfiles. I'm full stack developer but I mainly work on devops and backend. These are my configs. This is personal backup for myself but hopefully you find it useful too.

Big thanks for [@anttiviljami](https://github.com/anttiviljami) for years of guidance.
I hope someday I will learn to play [vimgolf](http://www.vimgolf.com/) but until then I will need these cheats.

### Stuff which is probably useful only for me
- Custom keyboard mappings with [karabiner-elements](https://karabiner-elements.pqrs.org)
- This includes my own keyboard layout based on Dvorak ( I implemented small tweaks for finnish language ).

## Installation on fresh MacOS
```sh
# Install Xcode Command line tools to get git
xcode-select --install

# Clone the dotfiles and run the installation script
git clone https://github.com/onnimonni/dotfiles ~/.dotfiles

~/.dotfiles/.install.sh

# Then create age key with secure enclave
mkdir -p ~/.config/sops/age/
age-plugin-se keygen --access-control none -o ~/.config/sops/age/secure-enclave-key.txt
```

## Using this config with your own user

`local-user.nix` is **gitignored** — each machine has its own copy. Generate one:
```sh
~/.dotfiles/scripts/generate-local-user.sh
```

Or copy the template manually:
```sh
cp ~/.dotfiles/local-user.nix.example ~/.dotfiles/local-user.nix
$EDITOR ~/.dotfiles/local-user.nix
```

The fields:
```nix
{
  hostname = "Your-Mac-Hostname";  # from: scutil --get LocalHostName
  username = "yourusername";       # from: whoami
  fullName = "Your Name";          # from: id -F
  email = "you@example.com";
  # Optional: enables the Mac Studio share tunnel (see "Sharing the Mac Studio" below).
  shareMacDomain = null;
}
```

Then rebuild:
```sh
sudo darwin-rebuild switch --flake ~/.dotfiles
```

This flake always exports `Onnis-MacBook-Pro` and `Onnis-Mac-Studio`.
`local-user.nix` selects the default host for convenience but does not hide the other one.

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

## Sharing the Mac Studio over Cloudflare Tunnel (SSH + VNC + Eternal Terminal)

Set `shareMacDomain = "<your-zone>"` in `local-user.nix` and the Mac Studio
becomes reachable at:

| Service | Public hostname | Local backend |
|---|---|---|
| SSH | `ssh-mac.<DOMAIN>` | `127.0.0.1:22` |
| VNC | `vnc-mac.<DOMAIN>` | `127.0.0.1:5900` |
| Eternal Terminal | `et-mac.<DOMAIN>` | `127.0.0.1:2022` |

Outbound-only — no port forwarding, no public SSH/VNC/ET exposure. Two locks:
Cloudflare Access (email OTP today, WebAuthn once Touch ID is enrolled) + SSH
keys from `github.com/<your-handle>.keys`.

`shareMacDomain` lives in gitignored `local-user.nix` so the zone never lands
in the public repo. Hostnames are intentionally single-level so they fit under
Cloudflare Free's `*.<DOMAIN>` Universal SSL cert.

### Connect from another Mac → Mac Studio

One-time setup on the client Mac:

```sh
# Add to ~/.dotfiles/local-user.nix on the client:
#   shareMacDomain = "<your-zone>";
sudo darwin-rebuild switch --flake ~/.dotfiles    # installs cloudflared + et + ssh config

# Pre-authenticate so the first remote-network attempt doesn't need a browser.
# Each hostname has its own cached Access token (~24h):
cloudflared access login ssh-mac.<DOMAIN>
cloudflared access login vnc-mac.<DOMAIN>
cloudflared access login et-mac.<DOMAIN>
ssh mac-studio echo hello                         # smoke test
```

Daily use (from anywhere — café Wi-Fi, hotel, phone tether, all the same):

```sh
# Shell over SSH (plain, no session persistence)
ssh mac-studio

# Shell over Eternal Terminal (survives network drops + sleep — like mosh but TCP)
et-mac-studio
# et-mac-studio is a generated wrapper: it boots a one-shot
# `cloudflared access tcp` listener for the ET data leg, ssh-bootstraps
# via cloudflared access ssh, then exec's `et`. Foreground subprocesses,
# no launchd.

# Files (works because ssh mac-studio works)
scp mac-studio:~/Projects/foo/bar.txt ./
rsync -avz mac-studio:~/Projects/foo/ ./foo/
sftp mac-studio

# GUI via Screen Sharing — needs two terminals:
#   terminal 1: open the TCP tunnel
cloudflared access tcp --hostname vnc-mac.<DOMAIN> --url localhost:5900
#   terminal 2 (or Finder ⌘K): connect VNC to the local end
open vnc://localhost:5900                         # VNC password is what you set in Sharing prefs
```

When the Access session expires, the next `ssh mac-studio` / `et-mac-studio`
re-opens a browser for email OTP; click through and it's good for another
session window.

If `ssh mac-studio` says `cloudflared: command not found`, the client hasn't
rebuilt with `shareMacDomain` set yet — re-run `sudo darwin-rebuild switch
--flake ~/.dotfiles`.

### Quick reference: what each command does

| Command | What it does |
|---|---|
| `ssh mac-studio` | Shell on the Mac Studio. ProxyCommand is the cloudflared tunnel; auth is your Secretive key. |
| `et-mac-studio` | Same shell, but over Eternal Terminal — resumes after network drops/sleep. Best with `tmux`/`zellij` on the far side for full session persistence. |
| `scp mac-studio:foo ./` | File copy. Same path, same auth. |
| `cloudflared access login <host>` | Refresh the Access session (browser flow). Cached at `~/.cloudflared/<host>-…-token`. |
| `cloudflared access tcp --hostname vnc-mac.<DOMAIN> --url localhost:5900` | Open a local TCP socket that proxies through the tunnel — for VNC, databases, anything TCP. |
| `cloudflared tunnel info mac-studio` (on the Mac Studio) | Show tunnel health and active connections. |

### Mac Studio bootstrap (one-time)

```sh
cloudflared tunnel login                          # browser → pick your zone
cloudflared tunnel create mac-studio              # writes ~/.cloudflared/<UUID>.json
sudo install -m 600 -o root -g wheel \
  ~/.cloudflared/<UUID>.json /etc/cloudflared/mac-studio.json
cloudflared tunnel route dns mac-studio ssh-mac.<DOMAIN>
cloudflared tunnel route dns mac-studio vnc-mac.<DOMAIN>
cloudflared tunnel route dns mac-studio et-mac.<DOMAIN>
# add shareMacDomain = "<your-zone>"; into local-user.nix
sudo darwin-rebuild switch --flake ~/.dotfiles
# System Settings → Sharing → Remote Login = On (Only these users → onnimonni)
# System Settings → Sharing → Screen Sharing = On + strong VNC password
```

### Cloudflare Zero Trust (one-time, in browser)

`one.dash.cloudflare.com` → Access controls → Applications → **Add → Self-hosted**:
- Public hostname: subdomain `ssh-mac`, domain `<your-zone>`. Session 24h.
- Policy: Allow your email.
- Repeat for `vnc-mac.<DOMAIN>` and `et-mac.<DOMAIN>`.

Universal SSL on Free covers `*.<DOMAIN>` only (one level) — keep the names
single-level.

### Harden once Touch ID is enrolled (recommended before travel)

Currently MFA is relaxed to "email OTP only". To upgrade to WebAuthn:

1. Access controls → Access settings → **Manage your App Launcher** → add Allow policy for your email. Save.
2. Browse to `https://<your-team>.cloudflareaccess.com`, log in, **Account → Setup MFA** → enroll Touch ID (Passkey) on every Mac + a hardware key as backup.
3. Back in Access settings → re-tick **Apply global MFA settings by default**.

After step 3, future sessions will prompt for Touch ID in the browser too.

### Verify the Mac Studio is reachable

```sh
sudo launchctl print system/com.cloudflare.cloudflared | head -5   # state = running
sudo launchctl print system/com.mistertea.etserver | head -5       # state = running
sudo tail -5 /var/log/cloudflared.log                              # 4 connections registered
sudo tail -5 /var/log/etserver.log                                 # etserver listening on 2022
ssh onnimonni@127.0.0.1 echo ok                                    # local sshd reachable
```

### Kill switch

Lost a key or laptop — Zero Trust → Access controls → Applications → pause or block the
policy. Tunnel stops authenticating in seconds, no router access required.

## Custom apps

### MenuBarChameleon
Swift app that dynamically tints the macOS menu bar based on window content below it.
Captures a color strip via ScreenCaptureKit, composites it onto the wallpaper top edge, and sets it as desktop image. macOS vibrancy then naturally samples the modified wallpaper.

```sh
# Build & install
apps/MenuBarChameleon/build.sh

# Run
open ~/Applications/MenuBarChameleon.app
```

Requires Screen Recording permission. Uses Apple Development signing identity for stable TCC.

## MCP
Githits and context7 MCP are configured for Claude and Codex via nix-darwin modules.
Codex Playwright MCP is re-added on nix-darwin rebuild via `codex mcp add playwright -- npx @playwright/mcp@latest --headless`.
Codex itself is installed via Homebrew cask.
`~/.codex/config.toml` is generated as writable file so Codex can persist its own model prefs.
Interactive shell sessions auto-handoff into `fish`.
Non-interactive shell entry via the login shell falls back to `bash`.
`claude`, `codex`, `gemini`, and `opencode` are wrapped via nix so they launch under bash with `SHELL=/bin/bash` instead of inheriting fish.
`consult-llm` is installed via nix and configured on activation to use `gemini-cli` and `codex-cli` backends.

## UNLICENSE
Use these dotfiles as you want to. Sharing is caring!
