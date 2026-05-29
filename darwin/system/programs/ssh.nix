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

      # Suppress post-quantum KEX warning for router (doesn't support it)
      extraConfig = ''
        Host 192.168.8.1
          LogLevel ERROR
      '';

      settings = {
        # Use ssh keys through secretive
        "*" = {
          IdentityAgent = "/Users/${username}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
        };

        # Use specific key for GitHub (no biometric prompts)
        "github.com" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/github_secretive.pub";
          IdentitiesOnly = true;
        };
      };
    };

  };
}
