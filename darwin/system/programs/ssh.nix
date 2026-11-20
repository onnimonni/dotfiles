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

      # IdentityAgent comes from keyfob's included ssh_config (programs/keyfob.nix);
      # home-manager wants a "*" block declared alongside extraConfig
      settings."*" = { };
    };

  };
}
