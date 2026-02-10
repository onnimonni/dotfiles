# Dotfiles aka nix-darwin configuration for onnimonni

This repository configures my MacBook.

It uses [nix-darwin](https://github.com/nix-darwin/nix-darwin)
through [determinate-nix](https://docs.determinate.systems/determinate-nix/).

**IMPORTANT: This is a public git repository so never ever add secrets to here**

## Example case
**IMPORTANT:** If I ask you to add new environmental variable to my shell you can't modify directly files in ~ but you have to modify ./darwin/**/*.nix files instead

## How to test if the configuration is working properly

```sh
nix flake check ~/.dotfiles
```

## How to enable new configuration

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/
```