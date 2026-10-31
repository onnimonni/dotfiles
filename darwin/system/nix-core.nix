# Nix package manager configuration for nix-darwin
{ username, ... }:
{
  # Allow unfree software like Claude Code
  nixpkgs.config.allowUnfree = true;

  # Nix daemon is managed outside nix-darwin (Determinate installer), so
  # `nix.settings` / `nix.gc` / `nix.optimise` are no-ops. Settings go into
  # /etc/nix/nix.custom.conf, which the installer's nix.conf `!include`s.
  # If nix.conf lacks the include, add `!include nix.custom.conf` manually
  # (tools that rewrite nix.conf, e.g. remote builder setup, may drop it).
  #
  # First rebuild aborts if an unmanaged nix.custom.conf exists; fix with:
  #   sudo mv /etc/nix/nix.custom.conf{,.before-nix-darwin}
  # Restart daemon after changes:
  #   sudo launchctl kickstart -k system/org.nixos.nix-daemon  (or systems.determinate.nix-daemon)
  nix.enable = false;

  environment.etc."nix/nix.custom.conf".text = ''
    # Managed by nix-darwin: ~/.dotfiles/darwin/system/nix-core.nix
    # trusted-users lets devenv pass substituters/keys without warnings
    trusted-users = root ${username}
    extra-substituters = https://devenv.cachix.org https://lazy-cow-tree.cachix.org
    extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= lazy-cow-tree.cachix.org-1:gpaT7lT1g7NZo5Na9qKQ5d6g4attS53Lm3A8rtZOjuw=
    extra-platforms = x86_64-darwin aarch64-darwin
    keep-outputs = true
    keep-derivations = true
    builders-use-substitutes = true
    # nix-rosetta-builder VM (rosetta-builder.nix; ssh config from its module).
    # Overrides the older builders line in /etc/nix/nix.conf (included before).
    builders = ssh-ng://rosetta-builder aarch64-linux,x86_64-linux - 10 1 benchmark,big-parallel,kvm,nixos-test
    warn-dirty = false
    # Parallel builds: one job per core; each job may use all cores
    max-jobs = auto
    cores = 0
  '';
}
