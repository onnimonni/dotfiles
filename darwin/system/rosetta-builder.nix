# Linux builder VM for NixOS systems built on this Mac (aarch64-linux natively,
# x86_64-linux via Rosetta 2), e.g. the ~/Projects/cloudflare-ssh servers, so
# they don't have to build their own (untrusted) systems.
# https://github.com/cpick/nix-rosetta-builder
#
# nix.enable = false here (the Determinate installer owns the daemon), so the
# module's nix.buildMachines is ignored: nix-core.nix adds the builders line.
# The VM (Lima, Virtualization.framework) binds to 127.0.0.1 only and starts on
# demand. Check: `sudo ssh rosetta-builder uname -m`.
_: {
  nix-rosetta-builder = {
    onDemand = true;
    cores = 10;
    memory = "32GiB";
    diskSize = "200GiB";
  };
}
