{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

rec {
  # Use VS Code as the default editor
  # To see all undocumented VS Code flags visit:
  # https://github.com/microsoft/vscode/blob/main/src/vs/platform/environment/node/argv.ts
  env.EDITOR = "code --wait --skip-welcome --skip-release-notes --disable-telemetry --skip-add-to-recently-opened";

  # I noticed that when typing $ sops secret.yaml, that copilot was enabled
  # This made me worry that the secrets were being sent to a remote server
  # Disable co-pilot and all other extensions when editing SOPS secrets
  env.SOPS_EDITOR = "${env.EDITOR} --new-window --disable-workspace-trust --disable-extensions";

  # Use age key which is securely generated with MacOS Secure Enclave
  # See docs/SECRETS.md for more
  # This can't be done with env because $HOME is not available for nix
  enterShell = ''
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/secure-enclave-key.txt"
  '';

  git-hooks.hooks = {
    # Nix files
    nixfmt-rfc-style.enable = true;

    # Leaking secrets
    trufflehog.enable = true;
    ripsecrets.enable = true;

    # Check that ssh/config doesn't contain HostName (capital N)
    check-ssh-hostname = {
      enable = true;
      name = "check-ssh-hostname";
      entry = "${pkgs.writeShellScript "check-ssh-hostname" ''
        #!/usr/bin/env bash

        # Check if ssh/config contains something it should not
        if [ -f "ssh/config" ] && grep -i -q "hostname" "ssh/config"; then
          echo ""
          echo "ERROR: ssh/config contains 'hostname'"
          echo "Use ~/.ssh/secret_config instead to avoid them from Github"
          echo ""
          exit 1
        fi

        exit 0
      ''}";
      files = "^ssh/config$";
      stages = [ "pre-commit" ];
    };
  };
}
