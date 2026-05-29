{ username, ... }:
let
  SSH_AUTH_SOCK = "/Users/${username}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
in
{
  homebrew.casks = [ "secretive" ];

  system.defaults.CustomUserPreferences."com.maxgoedjen.Secretive.Host" = {
    defaultsHasRunSetup = true;
  };

  home-manager.users.${username} = {
    home.sessionVariables = {
      inherit SSH_AUTH_SOCK;
    };

    programs.ssh.settings."*".IdentityAgent = SSH_AUTH_SOCK;

    home.file.".ssh/google_compute_engine".text = ''
      # Fake file to allow gcloud to work with secretive
    '';
  };
}
