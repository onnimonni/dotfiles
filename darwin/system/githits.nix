{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  realClaudeBin = "/opt/homebrew/bin/claude";
  hm = inputs.home-manager.lib.hm;
  hasSopsKey = builtins.pathExists "/Users/${username}/.config/sops/age/keys.txt";
in
{
  home-manager.users.${username} =
    { osConfig, ... }:
    {
      # Configure GitHits and Context7 MCP servers for Claude Code
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
        # Skill: always search GitHits/Context7 before concluding something is impossible
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
