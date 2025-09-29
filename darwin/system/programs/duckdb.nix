{ pkgs, ... }:
let
  latestDuckDB = pkgs.duckdb.version;
  # As of 2024-09, latest version is 1.4.0 but it's not yet merged for nixpkgs
  # We are overriding even that and using unreleased version instead
  expectedVersion = "1.4.0";
  customDuckDB = pkgs.duckdb.overrideAttrs (oldAttrs: rec {
    version = "1.4.0";
    rev = "b8a06e4a22672e254cd0baa68a3dbed2eb51c56e";
    src = pkgs.fetchFromGitHub {
      owner = "duckdb";
      repo = "duckdb";
      tag = "v${version}";
      sha256 = "sha256-ywQU+G8+VF+CiCb0Kgnx9cqKBBUEs4JG0iqh/OQS980=";
    };
  });
in
{
  environment.systemPackages = [
    # DuckDB for data mangling
    pkgs.duckdb
    #(if (latestDuckDB > expectedVersion)
    #  then (throw "DuckDB ${latestDuckDB} is newer than ${expectedVersion}. Custom override can be removed.")
    #  else customDuckDB)
  ];

  home-manager.users.onnimonni.home.file = {
    # Automatically load few duckdb extensions
    ".duckdbrc".text = ''
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
