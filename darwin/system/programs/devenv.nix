{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.devenv
  ];

  environment.variables = {
    # getconf works also in linux so it's more portable than $(sysctl -n hw.ncpu)
    DEVENV_CORES = "$(getconf _NPROCESSORS_ONLN)";
  };
}
