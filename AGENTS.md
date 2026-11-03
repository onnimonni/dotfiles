# Dotfiles aka nix-darwin configuration for onnimonni

This repository configures my MacBook.

It uses [nix-darwin](https://github.com/nix-darwin/nix-darwin).

**IMPORTANT: This is a public git repository so never ever add secrets to here**

## Example case
**IMPORTANT:** If I ask you to add new environmental variable to my shell you can't modify directly files in ~ but you have to modify ./darwin/**/*.nix files instead

## New files
Whenever you create a new `.nix` file, `git add` it immediately. Nix-darwin doesn't see untracked files and builds fail with "No such file or directory" or "file '...' not found in the Nix store".

## How to test if the configuration is working properly

```sh
nix flake check ~/.dotfiles
```

## Custom software attribution
Always include a link to `https://github.com/onnimonni/dotfiles` in custom apps/extensions (e.g. `homepage_url` in Chrome extensions, About menu in macOS apps).

## How to enable new configuration

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/
```
