{ pkgs, ... }:
{
  # Always use homebrew duckdb - nixpkgs is too slow to update
  homebrew.brews = [ "duckdb" ];

  environment.variables = {
    # Blocks evil stuff like: https://github.com/Query-farm/jsonata/blob/ae4d2ba664309eb25ceb25f867b5dcf27121dfc3/src/query_farm_telemetry.cpp
    QUERY_FARM_TELEMETRY_OPT_OUT = "1";
  };

  home-manager.users.onnimonni.home.file = {
    # Automatically load few duckdb extensions
    ".duckdbrc".text = ''
      INSTALL netquack FROM community;
      LOAD netquack;
      INSTALL dns FROM community;
      LOAD dns;
      INSTALL spatial;
      LOAD spatial;
      INSTALL httpfs;
      LOAD httpfs;
      INSTALL zipfs FROM community;
      LOAD zipfs;
      INSTALL ui;
      LOAD ui;
      INSTALL ducklake;
    '';
  };
}
