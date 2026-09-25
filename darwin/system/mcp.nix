{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
let
  codexBin = "/run/current-system/sw/bin/codex";
  codexPython = pkgs.python3.withPackages (packages: [ packages.tomlkit ]);
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
            linear-server = {
              url = "https://mcp.linear.app/mcp";
              type = "http";
            };
            playwright = {
              type = "stdio";
              command = "bunx";
              args = [ "@playwright/mcp@latest" ];
            };
          };
      };
    };

    home.activation.writeCodexConfig = hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Merging mutable Codex config..."

      mkdir -p /Users/${username}/.codex

      ${codexPython}/bin/python3 - <<'PY'
      from collections.abc import Mapping
      from pathlib import Path
      import os
      import tempfile
      import tomlkit

      config_path = Path("/Users/${username}/.codex/config.toml")
      config = tomlkit.parse(config_path.read_text()) if config_path.exists() else tomlkit.document()
      managed = tomlkit.parse("""
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
      """)

      def merge(target, source):
          for key, value in source.items():
              if isinstance(value, Mapping) and isinstance(target.get(key), Mapping):
                  merge(target[key], value)
              else:
                  target[key] = value

      merge(config, managed)
      config.pop("model", None)
      with tempfile.NamedTemporaryFile(mode="w", dir=config_path.parent, delete=False) as output:
          temporary_path = Path(output.name)
          try:
              output.write(tomlkit.dumps(config))
              output.flush()
              os.replace(temporary_path, config_path)
          finally:
              temporary_path.unlink(missing_ok=True)
      PY
    '';

    home.activation.configureCodexPlaywright = hm.dag.entryAfter [ "writeCodexConfig" ] ''
      echo "Configuring Codex Playwright MCP..."
      ${codexBin} mcp add playwright -- npx @playwright/mcp@latest --headless
    '';
  };
}
