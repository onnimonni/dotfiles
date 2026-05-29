# Nix package manager configuration for nix-darwin
{ pkgs, username, ... }:
{
  # Allow unfree software like Claude Code
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix manages its own daemon and conflicts with nix-darwin's
  # native Nix management. With `nix.enable = false`, nix-darwin defers to
  # Determinate — all `nix.settings`, `nix.gc`, `nix.optimise` options become
  # no-ops and must move to Determinate's own configuration paths instead:
  #
  #   * substituters / trusted-users / keep-outputs / warn-dirty
  #       → /etc/nix/nix.custom.conf (managed by Determinate)
  #   * GC schedule
  #       → systems.determinate.nix-gc plist or
  #         `determinate-nixd gc --interval ...`
  #   * Store optimization
  #       → handled automatically by determinate-nixd
  #
  # Trusted-users moved into /etc/nix/nix.custom.conf manually with:
  #   trusted-users = root <username>
  #   extra-substituters = https://devenv.cachix.org
  #   extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  #   keep-outputs = true
  #   keep-derivations = true
  #   builders-use-substitutes = true
  #   warn-dirty = false
  nix.enable = false;
}
