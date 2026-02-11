{ pkgs, username, ... }:
{
  environment.systemPackages = [
    # For opening any possible archive
    pkgs.atool
  ];

  home-manager.users.${username}.home.file = {
    # Even if files have .zip extension they are sometimes gunzipped
    ".atoolrc".text = ''
      # Don't trust file extensions. Use outputs of $ file always
      use_file_always 1
    '';
  };
}
