{ pkgs, lib, config, inputs, ... }:

{
  git-hooks.hooks = {
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
      stages = ["pre-commit"];
    };
  };
}
