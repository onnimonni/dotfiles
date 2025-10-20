{ pkgs, ... }:
{
  homebrew.brews = [
    # Homebrew has currently newer duckdb than nix
    # See more in: https://github.com/NixOS/nixpkgs/pull/444225
    (
      if (pkgs.duckdb.version > "1.4.0")
      then (throw "DuckDB ${pkgs.duckdb.version} is newer than 1.4.0. You can install duckdb again from nixpkgs.")
      else "duckdb"
    )
  ];

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
