{ inputs, username, ... }:
{
  # Secure Enclave keys for SSH, git commit signing, git credentials and age
  # (sops), unlocked with Touch ID: https://github.com/onnimonni/keyfob
  # Once per Mac: `keyfob init`, then add ~/.config/keyfob/ssh/default.pub to
  # GitHub as an authentication and a signing key.
  programs.keyfob = {
    enable = true;
    # sudo's Touch ID sheet names the command, its directory and who asked;
    # the password is the fallback (touchIdAuth is off in ../default.nix)
    sudo = true;
  };

  home-manager.users.${username} = {
    imports = [ inputs.keyfob.homeManagerModules.default ];
    # Agent at login + SSH_AUTH_SOCK, Include in ~/.ssh/config (IdentityAgent),
    # git signing + credential helper through programs.git
    programs.keyfob.enable = true;
    # sops keeps using ~/.config/sops/age/* (sops.nix, devenv.nix): those
    # age-plugin-se identities work unchanged, keyfob is age-plugin-se now.
    # New Macs: add `keyfob age-recipient` to .sops.yaml, `sops updatekeys`.

    # gcloud compute ssh expects this file even when keys come from an agent
    home.file.".ssh/google_compute_engine".text = ''
      # Placeholder: SSH keys come from the keyfob agent
    '';
  };
}
