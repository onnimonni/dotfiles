{
  inputs,
  lib,
  username,
  ...
}:
let
  codexBin = "/run/current-system/sw/bin/codex";
  hm = inputs.home-manager.lib.hm;
  hasSopsKey = builtins.pathExists "/Users/${username}/.config/sops/age/keys.txt";
in
{
  # Home-manager configuration for mcp
  home-manager.users.${username} = {
    home.file = {
      ".mcp.json".text = builtins.toJSON {
        mcpServers =
          lib.optionalAttrs hasSopsKey {
            GitHits = {
              url = "https://mcp.githits.com";
              type = "http";
            };
          }
          // {
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
    };

    home.activation.writeCodexConfig = hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Writing mutable Codex config..."

      mkdir -p /Users/${username}/.codex

      if [ -L /Users/${username}/.codex/config.toml ]; then
        rm /Users/${username}/.codex/config.toml
      fi

      cat > /Users/${username}/.codex/config.toml <<'EOF'
      model = "gpt-5.3-codex"

      [projects."/Users/${username}"]
      trust_level = "trusted"

      [projects."/Users/${username}/.dotfiles"]
      trust_level = "trusted"
      ${lib.optionalString hasSopsKey ''

        [mcp_servers.GitHits]
        transport = "streamable_http"
        url = "https://mcp.githits.com/"
        bearer_token_env_var = "GITHITS_API_TOKEN"
      ''}

      [mcp_servers.context7]
      transport = "streamable_http"
      url = "https://mcp.context7.com/mcp"

      [mcp_servers.context7.env_http_headers]
      CONTEXT7_API_KEY = "CONTEXT7_API_KEY"
      EOF

      chmod 600 /Users/${username}/.codex/config.toml
    '';

    home.activation.configureCodexPlaywright = hm.dag.entryAfter [ "writeCodexConfig" ] ''
      echo "Configuring Codex Playwright MCP..."
      ${codexBin} mcp add playwright -- npx @playwright/mcp@latest --headless
    '';
  };
}
