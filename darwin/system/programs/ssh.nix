{ pkgs, username, ... }:
{
  home-manager.users.${username} = {
    # Configure SSH to include secret_config
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [
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

  };
}
