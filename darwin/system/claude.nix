{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  # Real claude binary from homebrew
  realClaudeBin = "/opt/homebrew/bin/claude";

  # Wrapper that runs claude under zsh (fish has compatibility issues)
  claudeWrapper = pkgs.writeShellScriptBin "claude" ''
    export SHELL=/bin/zsh
    exec /bin/zsh -l -c 'exec ${realClaudeBin} "$@"' -- "$@"
  '';

  # home-manager lib for dag functions
  hm = inputs.home-manager.lib.hm;
in
{
  # Install claude-code via homebrew cask (newer than nixpkgs)
  homebrew.casks = [ "claude-code" ];

  # Add wrapper to system PATH (before homebrew)
  environment.systemPackages = [ claudeWrapper ];

  # Home-manager configuration for claude
  home-manager.users.${username} =
    { osConfig, ... }:
    {
      # Create a home activation script to enable MCP servers for claude code.
      home.activation = {
        configureClaudeMCP = hm.dag.entryAfter [ "writeBoundary" ] ''
          echo "Configuring Claude MCP servers..."

          echo "Configuring Githits..."
          ${realClaudeBin} mcp get GitHits > /dev/null 2>&1 || \
            ${realClaudeBin} mcp add \
              --transport http \
              GitHits \
              --scope user \
              https://mcp.githits.com/ \
              --header "Authorization: Bearer $(cat ${osConfig.sops.secrets.githits_api_key.path})"

          echo "Configuring Context7..."
          ${realClaudeBin} mcp get context7 > /dev/null 2>&1 || \
            ${realClaudeBin} mcp add \
              --transport http \
              context7 \
              --scope user \
              https://mcp.context7.com/mcp \
              --header "CONTEXT7_API_KEY: $(cat ${osConfig.sops.secrets.context7_api_key.path})"
        '';
      };

      home.file = {
        # See more in https://docs.claude.com/en/docs/claude-code/settings
        # Longer timeouts were needed to compile large programs like duckdb
        # Disable telemetry and error reporting and feedback surveys
        # Source: https://www.vincentschmalbach.com/configuring-claude-code-for-privacy-and-noise-control/
        ".claude/settings.json".text = ''
          {
            "$schema": "https://json.schemastore.org/claude-code-settings.json",
            "alwaysThinkingEnabled": true,
            "feedbackSurveyState": {
              "lastShownTime": 1754109357477
            },
            "includeCoAuthoredBy": false,
            "env": {
              "BASH_DEFAULT_TIMEOUT_MS": "1800000",
              "BASH_MAX_TIMEOUT_MS": "3600000",
              "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1",
              "DISABLE_TELEMETRY": "1",
              "DISABLE_ERROR_REPORTING": "1",
              "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1"
            },
            "UserPromptSubmit": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "~/.claude/hooks/claudeception-activator.sh"
                  }
                ]
              }
            ]
          }
        '';

        # Global instructions for Claude Code
        ".claude/CLAUDE.md".text = ''
          # More instructions in
          @~/.agents/AGENTS.md

          ## Creating PRs for 3rd party repos

          When user says "Create a PR for 3rd party repo" or similar:

          1. Check repo size with `gh api repos/{owner}/{repo} --jq .size` — if over 5000000 KB (≈5GB), use GitHub API/fetch instead or ask user to confirm before cloning
          2. Clone the repo locally to /tmp/ using `git clone --depth 1` (NOT gh api calls)
          3. Explore the code locally using filesystem tools (Read, Grep, Glob) instead of GitHub API
          4. Create a branch, make changes, commit, push, then create PR with `gh pr create`

          Prefer local exploration over API-based file fetching for understanding the codebase.
        '';
      };
    };
}
