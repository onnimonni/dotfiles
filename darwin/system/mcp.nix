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
      ".mcp.json".text = builtins.toJSON {
        mcpServers = {
          GitHits = {
            url = "https://mcp.githits.com";
            type = "http";
          };
          context7 = {
            url = "https://mcp.context7.com/mcp";
            type = "http";
          };
          playwright = {
            type = "stdio";
            command = "bunx";
            args = [ "@playwright/mcp@latest" ];
          };
          consult-llm = {
            type = "stdio";
            command = "bunx";
            args = [
              "-y"
              "consult-llm-mcp"
            ];
            env = {
              CONSULT_LLM_DEFAULT_MODEL = "gemini-3.1-pro-preview";
              CONSULT_LLM_ALLOWED_MODELS = "gemini-3.1-pro-preview";
            };
          };
        };
      };

      ".codex/config.toml".text = ''
        model = "gpt-5.3-codex"

        [projects."/Users/${username}"]
        trust_level = "trusted"

        [projects."/Users/${username}/.dotfiles"]
        trust_level = "trusted"

        [mcp_servers.GitHits]
        transport = "streamable_http"
        url = "https://mcp.githits.com/"
        bearer_token_env_var = "GITHITS_API_TOKEN"

        [mcp_servers.context7]
        transport = "streamable_http"
        url = "https://mcp.context7.com/mcp"

        [mcp_servers.context7.env_http_headers]
        CONTEXT7_API_KEY = "CONTEXT7_API_KEY"
      '';
    };
  };
}
