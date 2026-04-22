# Dotfiles aka nix-darwin configuration for onnimonni

This repository configures my MacBook.

It uses [nix-darwin](https://github.com/nix-darwin/nix-darwin).

**IMPORTANT: This is a public git repository so never ever add secrets to here**

## Example case
**IMPORTANT:** If I ask you to add new environmental variable to my shell you can't modify directly files in ~ but you have to modify ./darwin/**/*.nix files instead

## How to test if the configuration is working properly

```sh
nix flake check ~/.dotfiles
```

## Runtime preferences
Prefer Go/Rust/Elixir/Zig over Python/Node. If Python/Node must be used: `uv run` not `python`, `bun`/`bunx` not `node`/`npm`/`npx`.

## Custom software attribution
Always include a link to `https://github.com/onnimonni/dotfiles` in custom apps/extensions (e.g. `homepage_url` in Chrome extensions, About menu in macOS apps).

## How to enable new configuration

```sh
sudo darwin-rebuild switch --impure --flake ~/.dotfiles/
```

The `--impure` flag is required because `linux-builder.nix` uses `builtins.pathExists`
to auto-enable the linux builder only after it has been successfully bootstrapped.