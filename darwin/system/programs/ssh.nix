{ pkgs, ... }:
{
  # Configure SSH to include secret_config
  home-manager.users.onnimonni.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.colima/ssh_config"
      "~/.ssh/secret_config"
    ];

    # Use ssh keys through secretive
    matchBlocks."*" = {
      identityAgent = "/Users/onnimonni/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
  };
}
