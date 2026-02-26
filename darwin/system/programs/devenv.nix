{ pkgs, username, ... }:
{
  environment.systemPackages = [
    pkgs.devenv
  ];

  environment.variables = {
    # getconf works also in linux so it's more portable than $(sysctl -n hw.ncpu)
    DEVENV_CORES = "$(getconf _NPROCESSORS_ONLN)";
    DEVENV_MAX_JOBS = "$(getconf _NPROCESSORS_ONLN)";
  };

  home-manager.users.${username} = {
    home.file.".config/direnv/direnv.toml".text = ''
      [global]
      hide_env_diff = true
      warn_timeout = "30s"
    '';
  };
}
