{
  config,
  lib,
  username,
  ...
}:
let
  keyFile = "/Users/${username}/.config/sops/age/keys.txt";
in
{
  sops = {
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

    # Owned by user so home-manager activation can read them from /run/secrets/<name>
    # MCP configuration: darwin/system/githits.nix, darwin/system/mcp.nix, darwin/system/programs/mcp-secrets.nix
    secrets = {
      githits_api_key.owner = username;
      context7_api_key.owner = username;
      stitch_api_key.owner = username;
    };
  };
}
