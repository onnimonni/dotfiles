{
  pkgs,
  inputs,
  username,
  ...
}:
let
  lazy-cow-tree = inputs.lazy-cow-tree.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment.systemPackages = [
    inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv
    lazy-cow-tree
  ];

  environment.variables = {
    # getconf works also in linux so it's more portable than $(sysctl -n hw.ncpu)
    DEVENV_CORES = "$(getconf _NPROCESSORS_ONLN)";
    DEVENV_MAX_JOBS = "$(getconf _NPROCESSORS_ONLN)";
    # One proxy on :80/:443 for every repo: when none runs, `devenv up` starts
    # lazy-cow-tree instead of devenv-proxy, and devenv projects register with it.
    DEVENV_PROXY_BINARY = "${lazy-cow-tree}/bin/lazy-cow-tree-devenv-proxy";
  };

  home-manager.users.${username} = {
    home.file.".config/direnv/direnv.toml".source = (pkgs.formats.toml { }).generate "direnv.toml" {
      global = {
        hide_env_diff = true;
        warn_timeout = "30s";
      };
    };
  };
}
