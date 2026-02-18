{
  config,
  lib,
  username,
  ...
}:
let
  keyFile = "/Users/${username}/.config/sops/age/keys.txt";
  hasKeyFile = builtins.pathExists keyFile;
in
{
  # Only enable sops when age key file exists on this machine
  sops = lib.mkIf hasKeyFile {
    defaultSopsFile = ../../secrets/secrets.yaml;

    # Prevents storing the sops files to the nix store
    validateSopsFiles = false;

    # Don't generate GPG keys from RSA, AGE keys come through the copied HOST keys
    gnupg.sshKeyPaths = [ ];

    # Use age for encryption instead of GPG
    age = {
      inherit keyFile;
      # Don't try to convert SSH keys to age keys
      sshKeyPaths = [ ];
    };

    secrets = {
      githits_api_key = {
        # This secret will be available at /run/secrets-for-users/${username}/githits_api_key
        # The MCP configuration is done in darwin/system/programs/claude.nix
      };
      context7_api_key = {
        # This secret will be available at /run/secrets-for-users/${username}/context7_api_key
        # The MCP configuration is done in darwin/system/programs/claude.nix
      };
    };
  };
}
