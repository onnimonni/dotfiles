{
  config,
  pkgs,
  lib,
  username,
  ...
}:
{
  # Home-manager configuration for mcp
  home-manager.users.${username} = {
    home.file = {
      ".mcp.json".text = ''
        {
          "servers": {
            "GitHits": {
              "url": "https://mcp.githits.com",
              "type": "http"
            }
          }
        }
      '';
    };
  };
}
