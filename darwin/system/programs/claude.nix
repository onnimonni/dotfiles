{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.claude-code
  ];

  home-manager.users.onnimonni.home.file = {
    # See more in https://docs.claude.com/en/docs/claude-code/settings
    # These were needed to compile large C-programs like duckdb
    ".claude/settings.json".text = ''
      {
        "env": {
          "BASH_DEFAULT_TIMEOUT_MS": "1800000",
          "BASH_MAX_TIMEOUT_MS: "3600000"
        }
      }
    '';
  };
}
