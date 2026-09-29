{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  # Use the store path directly during activation, before PATH is updated.
  realClaudeBin = lib.getExe pkgs.claude-code;
  hm = inputs.home-manager.lib.hm;

  # Claude Code runs headersHelper on each MCP connection, so the key is read from
  # /run/secrets at runtime and never written into ~/.claude.json.
  mkHeadersHelper =
    name: header: prefix: secretPath:
    pkgs.writeShellScript "claude-mcp-headers-${name}" ''
      set -eu
      secret_file=${lib.escapeShellArg secretPath}
      if [ ! -r "$secret_file" ]; then
        echo "claude-mcp-headers-${name}: $secret_file missing or unreadable" >&2
        exit 1
      fi
      key=$(< "$secret_file")
      if [ -z "$key" ]; then
        echo "claude-mcp-headers-${name}: $secret_file is empty" >&2
        exit 1
      fi
      ${lib.getExe pkgs.jq} -cn --arg v ${lib.escapeShellArg prefix}"$key" '{${builtins.toJSON header}: $v}'
    '';
in
{
  home-manager.users.${username} =
    { osConfig, ... }:
    let
      servers = {
        GitHits = {
          url = "https://mcp.githits.com/";
          helper =
            mkHeadersHelper "githits" "Authorization" "Bearer "
              osConfig.sops.secrets.githits_api_key.path;
        };
        context7 = {
          url = "https://mcp.context7.com/mcp";
          helper =
            mkHeadersHelper "context7" "CONTEXT7_API_KEY" ""
              osConfig.sops.secrets.context7_api_key.path;
        };
        stitch = {
          url = "https://stitch.googleapis.com/mcp";
          helper = mkHeadersHelper "stitch" "X-Goog-Api-Key" "" osConfig.sops.secrets.stitch_api_key.path;
        };
      };
    in
    {
      # Configure GitHits, Context7 and Stitch MCP servers for Claude Code
      home.activation = {
        configureClaudeMCP = hm.dag.entryAfter [ "claudeSettings" ] ''
          echo "Configuring Claude MCP servers..."

          # Re-add on every activation so helper store paths stay current
          configure_mcp() {
            local name="$1" json="$2"
            echo "Configuring $name..."
            ${realClaudeBin} mcp remove "$name" --scope user > /dev/null 2>&1 || true
            ${realClaudeBin} mcp add-json "$name" "$json" --scope user > /dev/null
          }

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: server:
              "configure_mcp ${name} ${
                lib.escapeShellArg (
                  builtins.toJSON {
                    type = "http";
                    inherit (server) url;
                    headersHelper = "${server.helper}";
                  }
                )
              }"
            ) servers
          )}
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
