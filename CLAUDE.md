# Dotfiles aka nix-darwin configuration for onnimonni

This repository configures MacBook for me.

It uses [nix-darwin](https://github.com/nix-darwin/nix-darwin)
through [determinate-nix](https://docs.determinate.systems/determinate-nix/).

I use fish shell so aliases and environment variables should always exist at least in fish.

**IMPORTANT: This is a public git repository so never ever add secrets to here**

## How to test if the configuration is working properly

```sh
nix flake check --flake ~/.dotfiles
```

## How to enable new configuration

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/
```