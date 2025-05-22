{ pkgs, ... }:
{
  environment.systemPackages = [
    # DuckDB for data mangling
    pkgs.duckdb
  ];

  home-manager.users.onnimonni.home.file = {
    # Automatically load few duckdb extensions
    ".duckdbrc".text = ''
      LOAD spatial;
      LOAD cache_httpfs;
      LOAD zipfs;
    '';
  };
}
