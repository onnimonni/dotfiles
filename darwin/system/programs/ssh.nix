{ pkgs, username, ... }:
let
  # Public key for GitHub (no biometric auth required in Secretive)
  githubPubKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAu0qCU51pzJP6GaHRDT5pqGsfMw9qlTTMTnxFo3ppoQekYWwB+9Liyrm0giBR2LxQu1x5G3S7h8xw3sjxHQq4w= github-key";
in
{
  home-manager.users.${username} = {
    # Configure SSH to include secret_config
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [
        "~/.colima/ssh_config"
        "~/.ssh/secret_config"
      ];

      # Use ssh keys through secretive
      matchBlocks."*" = {
        identityAgent = "/Users/${username}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      };

      # Use specific key for GitHub (no biometric prompts)
      matchBlocks."github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/github_secretive.pub";
        identitiesOnly = true;
      };
    };

    # Store public key so SSH can match it to Secretive agent
    home.file.".ssh/github_secretive.pub".text = githubPubKey;
  };
}
