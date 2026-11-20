{ pkgs, ... }:
{
  imports = [
    ./ai-cli-bash.nix
    ./nix-core.nix
    ./settings.nix
    ./user.nix
    ./homebrew.nix
    ./programs.nix
    ./sops.nix
    ./claude.nix
    ./gemini.nix
    ./consult-llm.nix
    ./agents.nix
    ./mcp.nix
    ./githits.nix
    ./rosetta-builder.nix
  ];

  # Pretty nice examples for setting up nix-darwin: https://github.com/thurstonsand/nixonomicon

  # The default Nix build user group ID was changed from 30000 to 350.
  # You are currently managing Nix build users with nix-darwin, but your
  # nixbld group has GID 350, whereas we expected 30000.
  ids.gids.nixbld = 350;

  # sudo uses Touch ID through keyfob (programs/keyfob.nix), whose sheet names
  # the command. No pam_tid after it: denying keyfob must not lead to a generic
  # Touch ID sheet that is easy to approve by reflex; the password stays.
  security.pam.services.sudo_local.touchIdAuth = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Rosetta: extra-platforms set in nix-core.nix (nix.custom.conf).
}
