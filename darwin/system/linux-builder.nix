# Linux builder VM for building aarch64-linux derivations on macOS
#
# Bootstrap: first darwin-rebuild creates /etc/nix/linux-builder.enabled,
# second darwin-rebuild sees the flag and enables the builder with defaults.
# Custom VM settings (disk/memory/gc) are applied once the builder can
# build its own aarch64-linux derivations.
# Requires --impure flag for builtins.pathExists.
{ pkgs, lib, ... }:
let
  enableBuilder = builtins.pathExists /etc/nix/linux-builder.enabled;
  # The builder needs to build its own VM config derivations on aarch64-linux.
  # Custom config (gc, diskSize, etc.) creates non-cached derivations that fail
  # without a running builder. Only apply custom config once builder is running.
  builderRunning = builtins.pathExists /var/run/org.nixos.linux-builder;
in
{
  # Create flag file so the NEXT rebuild enables the builder
  system.activationScripts.postActivation.text = ''
    touch /etc/nix/linux-builder.enabled
  '';

  nix.linux-builder = {
    enable = enableBuilder;
    ephemeral = true;
    maxJobs = 8;
    systems = [ "aarch64-linux" ];
    config = lib.mkIf builderRunning {
      nix.gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      virtualisation = {
        darwin-builder = {
          diskSize = 25 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 8;
      };
    };
  };
}
