{ pkgs, ... }:
{
  environment.systemPackages = [
    # DuckDB for data mangling
    pkgs.duckdb
  ];

  home-manager.users.onnimonni.home.file = {
    # Automatically load few duckdb extensions
    ".duckdbrc".text = ''
      INSTALL spatial;
      LOAD spatial;
      INSTALL cache_httpfs FROM community;
      LOAD cache_httpfs;
      INSTALL zipfs FROM community;
      LOAD zipfs;
      INSTALL ui;
      LOAD ui;
    '';
  };
}
