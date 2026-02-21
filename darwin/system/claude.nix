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

  # Only configure MCP secrets when sops age key exists
  hasSopsKey = builtins.pathExists "/Users/${username}/.config/sops/age/keys.txt";
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
      # Only configure secrets when sops age key exists on this machine.
      home.activation = lib.mkIf hasSopsKey {
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

        # Skills
        ".claude/skills/never-conclude-impossible/SKILL.md".text = ''
          ---
          name: never-conclude-impossible
          description: |
            MANDATORY check before concluding something "can't be done", "isn't possible",
            "not supported", or "no way to". Use when: (1) about to tell user a feature doesn't
            exist, (2) about to say something can't be configured/automated, (3) about to
            recommend manual workaround as only option, (4) concluding a tool/API/system lacks
            a capability. Covers: macOS defaults, system preferences, CLI tools, library
            limitations, API restrictions, undocumented features.
          author: Claude Code
          version: 1.0.0
          date: 2026-02-21
          ---

          # Never Conclude Impossible Without Searching First

          ## Problem
          Claude's training data has a knowledge cutoff and doesn't cover undocumented features,
          community workarounds, or reverse-engineered solutions. Concluding "can't be done" based
          solely on training knowledge leads to wrong answers when workarounds exist.

          ## Context / Trigger Conditions
          **BEFORE saying any of these, you MUST search GitHits and Context7 first:**
          - "Unfortunately, this can't be done..."
          - "There's no way to..."
          - "This isn't supported..."
          - "The only option is to do it manually..."
          - "This can't be automated..."
          - "No built-in preference/setting for..."
          - "Not possible via defaults write / CLI / API..."

          ## Solution

          1. **Catch yourself** before concluding impossibility
          2. **Search GitHits** with a specific query about the workaround:
             - Include the tool/system name (e.g., "macOS", "ncprefs", "defaults write")
             - Include what you're trying to achieve
             - Include relevant identifiers (bundle IDs, config keys, etc.)
          3. **Search Context7** for library/framework-specific solutions
          4. **Only after searching** and finding no results, tell the user it appears unsupported
             — but frame it as "I couldn't find a way" not "it's impossible"

          ## Verification
          - Did you search GitHits before concluding? If not, search now.
          - Did you search Context7 for relevant library docs? If not, search now.
          - Are you framing the conclusion as "I couldn't find" rather than "impossible"?

          ## Example

          ### BAD (what happened):
          > "Maccy has no built-in preference to disable notifications. macOS notification
          > settings can't be managed via defaults write or nix-darwin."

          ### GOOD (what should have happened):
          > "Let me search for workarounds before concluding..."
          > *searches GitHits for "macOS disable notifications per app com.apple.ncprefs"*
          > *finds ncprefs flags bitmask approach*
          > "macOS stores these in com.apple.ncprefs as a flags bitmask. Here's how to
          > manipulate it programmatically..."

          ## Notes
          - Undocumented features and reverse-engineered solutions are common in macOS, Windows, Linux
          - Open source repos often contain workarounds that official docs don't mention
          - The community frequently finds ways around "impossible" limitations
          - Even if something truly can't be done, searching first builds user trust
        '';
      };
    };
}
