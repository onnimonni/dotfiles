{
  pkgs,
  inputs,
  username,
  ...
}:
let
  # Base settings managed by nix - tools like nono can merge their own keys on top
  # See more in https://docs.claude.com/en/docs/claude-code/settings
  # Longer timeouts were needed to compile large programs like duckdb
  # Disable error reporting and feedback surveys
  # Source: https://www.vincentschmalbach.com/configuring-claude-code-for-privacy-and-noise-control/
  claudeSettingsBase = builtins.toJSON {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    # Detect terminal background so light iTerm themes stay readable
    theme = "auto";
    alwaysThinkingEnabled = true;
    feedbackSurveyState = {
      lastShownTime = 1754109357477;
    };
    includeCoAuthoredBy = false;
    env = {
      BASH_DEFAULT_TIMEOUT_MS = "1800000";
      BASH_MAX_TIMEOUT_MS = "3600000";
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
      # Keep DISABLE_TELEMETRY and CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC unset
      # for Remote Control and the Monitor tool.
      # https://code.claude.com/docs/en/tools-reference#monitor-tool
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
    };
  };
in
{
  homebrew.brews = [ "nono" ];

  # Use the newer npm release with nixpkgs' native-binary packaging.
  # The bash wrapper in ./ai-cli-bash.nix exposes it on PATH.
  nixpkgs.overlays = [
    (final: prev: {
      claude-code = final.callPackage ../packages/claude-code.nix {
        inherit (prev) claude-code;
      };
    })
  ];

  # Home-manager configuration for claude
  home-manager.users.${username} = {
    home.file = {
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

    # Keybindings: § key (next to Tab) for push-to-talk, unbind space
    home.file.".claude/keybindings.json".text = builtins.toJSON {
      "$schema" = "https://www.schemastore.org/claude-code-keybindings.json";
      "$docs" = "https://code.claude.com/docs/en/keybindings";
      bindings = [
        {
          context = "Chat";
          bindings = {
            "\`" = "voice:pushToTalk";
            space = null;
          };
        }
      ];
    };

    # Write settings.json as a regular writable file (not a symlink)
    # so tools like nono can modify it at runtime.
    # Uses jq to deep-merge: nix base settings * existing tool-added keys
    home.activation.claudeSettings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SETTINGS="$HOME/.claude/settings.json"
      BASE_SETTINGS='${claudeSettingsBase}'

      mkdir -p "$(dirname "$SETTINGS")"

      # Remove stale nix-store symlink from previous config
      if [ -L "$SETTINGS" ]; then
        rm "$SETTINGS"
      fi

      if [ -f "$SETTINGS" ]; then
        # Deep-merge: nix base wins for shared keys, preserve tool-added keys
        # Remove old flags so Remote Control and Monitor remain available.
        MERGED=$(${pkgs.jq}/bin/jq -s '.[1] * .[0] | del(.env.DISABLE_TELEMETRY, .env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)' <(echo "$BASE_SETTINGS") "$SETTINGS")
        echo "$MERGED" | ${pkgs.jq}/bin/jq . > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
      else
        echo "$BASE_SETTINGS" | ${pkgs.jq}/bin/jq . > "$SETTINGS"
      fi
    '';
  };
}
