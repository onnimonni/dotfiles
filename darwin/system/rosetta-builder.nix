# Linux builder VM for NixOS systems built on this Mac (aarch64-linux natively,
# x86_64-linux via Rosetta 2), e.g. the ~/Projects/cloudflare-ssh servers, so
# they don't have to build their own (untrusted) systems.
# https://github.com/cpick/nix-rosetta-builder
#
# nix.enable = false here (the installer owns the daemon), so the module's
# nix.buildMachines is ignored: the builders line is added to nix.custom.conf below.
# The VM (Lima, Virtualization.framework) binds to 127.0.0.1 only and starts on
# demand. Check: `sudo ssh rosetta-builder uname -m`.
#
# Disabled until bootstrapped: the VM image is aarch64-linux, so building it
# needs an existing Linux builder, and nix-darwin's nix.linux-builder requires
# nix.enable = true. To bootstrap once:
#   1. In another terminal: nix run nixpkgs#darwin.linux-builder
#      (prebuilt in cache.nixos.org) and follow its instructions to add it as
#      a builder.
#   2. Set enable = true below and `sudo darwin-rebuild switch --flake ~/.dotfiles/`.
#   3. Stop the linux-builder. From then on the rosetta builder rebuilds itself.
{ lib, ... }:
let
  enable = false;
in
{
  nix-rosetta-builder = {
    inherit enable;
    onDemand = true;
    cores = 10;
    memory = "32GiB";
    diskSize = "200GiB";
  };

  environment.etc."nix/nix.custom.conf".text = lib.mkIf enable (
    lib.mkAfter ''
      # nix-rosetta-builder VM; overrides the builders line in /etc/nix/nix.conf
      builders = ssh-ng://rosetta-builder aarch64-linux,x86_64-linux - 10 1 benchmark,big-parallel,kvm,nixos-test
    ''
  );
}
