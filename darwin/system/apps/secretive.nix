{...}:
let
  SSH_AUTH_SOCK = "/Users/onnimonni/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
in {
  homebrew.casks = [ "secretive" ];

  system.defaults.CustomUserPreferences."com.maxgoedjen.Secretive.Host" = {
    defaultsHasRunSetup = true;
  };

  home-manager.users.onnimonni.home.sessionVariables = {
    inherit SSH_AUTH_SOCK;
  };

  home-manager.users.onnimonni.programs.ssh.matchBlocks."*".extraOptions."IdentityAgent" = SSH_AUTH_SOCK;

  home-manager.users.onnimonni.home.file = {
    ".ssh/google_compute_engine".text = ''
      # Fake file to allow gcloud to work with secretive
    '';
  };
}
