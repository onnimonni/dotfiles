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

    # Owned by user so MCP header helpers and shells can read /run/secrets/<name> at runtime
    # MCP configuration: darwin/system/githits.nix, darwin/system/mcp.nix, darwin/system/programs/mcp-secrets.nix
    secrets = {
      githits_api_key.owner = username;
      context7_api_key.owner = username;
      stitch_api_key.owner = username;
    };
  };

  # sops-nix installs secrets in postActivation (mkAfter), after home-manager has run.
  # Install them first too, so this rebuild's owners/values are visible to home-manager.
  system.activationScripts.preActivation.text = lib.mkBefore ''
    echo "Setting up secrets before home-manager..."
    ${config.sops.package}/bin/sops-install-secrets ${config.system.build.sops-nix-manifest}
  '';
}
