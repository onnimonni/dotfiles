{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.devenv
  ];

  environment.variables = {
    DEVENV_CORES = "$(sysctl -n hw.ncpu)";
  };
}
