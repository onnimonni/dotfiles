{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # claude binary path from homebrew
  claudeBin = "/opt/homebrew/bin/claude";

  # home-manager lib for dag functions
  hm = inputs.home-manager.lib.hm;
in
{
  # Install claude-code via homebrew cask (newer than nixpkgs)
  homebrew.casks = [ "claude-code" ];

  # Home-manager configuration for claude
  home-manager.users.onnimonni =
    { osConfig, ... }:
    {
      # Create a home activation script to enable MCP servers for claude code.
      home.activation = {
        configureClaudeMCP = hm.dag.entryAfter [ "writeBoundary" ] ''
          echo "Configuring Claude MCP servers..."

          echo "Configuring Githits..."
          ${claudeBin} mcp get GitHits > /dev/null 2>&1 || \
            ${claudeBin} mcp add \
              --transport http \
              GitHits \
              --scope user \
              https://mcp.githits.com/ \
              --header "Authorization: Bearer $(cat ${osConfig.sops.secrets.githits_api_key.path})"

          echo "Configuring Context7..."
          ${claudeBin} mcp get context7 > /dev/null 2>&1 || \
            ${claudeBin} mcp add \
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
            }
          }
        '';

        # Global instructions for Claude Code
        ".claude/CLAUDE.md".text = ''
          IMPORTANT: In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

          ## GitHub

          - Your primary method for interacting with GitHub should be the GitHub CLI (gh).

          ## Use Githits and context7 MCP servers
          Instead of using 'Web Search' skill, prefer using the Githits and context7 MCP servers for fetching up-to-date information.

          These can provide help when you want to find code examples and libraries and function documentation.

          ## Plans

          - At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

          ## Avoid calling system shells from the code

          NEVER EVER use `popen` or `system()` or `shell()` or similiar methods for running commands from other coding language.
          If problem can't be solved in other ways you need to inform the user about it.
          Using binaries in $PATH is only allowed in bash scripts but not in other programming languages.

          ## Use env in shell scripts

          Shell scripts should start like this:
          ```
          #!/usr/bin/env bash
          ```

          ## Using environmental variables with make

          env like `GEN=ninja` need to be used after the make command, not before it:

          ```sh
          make release GEN=ninja VCPKG_TOOLCHAIN_PATH=$(pwd)/vcpkg/scripts/buildsystems/vcpkg.cmake
          ```

          ## System clock

          Don't trust your memory; you cannot remember time accurately.
          If you need to get the current time use:

          ```sh
          date
          ```

          ## DuckDB

          You can enable timer by running `.timer on` command in duckdb sql script.

          ### Printing messages
          You can't print in duckdb scripts. This doesn't work:

          ```sql
          .echo Done!
          ```

          Instead you need to:

          ```sql
          SELECT "Done!" as status
          ```

          ## Duckdb CLI file flag
          If you want to run SQL files with duckdb CLI use:

          ```sh
          duckdb -f myscript.sql
          ```

          ### Querying JSON/structured data in varchar columns
          NEVER use LIKE to query varchar columns containing JSON or structured data. Parse it properly:

          ```sql
          -- BAD: Using LIKE to find JSON values
          SELECT * FROM table WHERE data LIKE '%"key": "value"%';

          -- GOOD: Parse JSON and query properly
          SELECT * FROM table WHERE json_extract_string(data, '$.key') = 'value';
          ```

          If proper parsing tools/extensions aren't available, tell user to build/find them rather than using LIKE.

          ## Failing git commit

          **IMPORTANT: You are never allowed to use: `--no-verify` or `--no-gpg-sign` in git commits**

          Git commit hooks verify that code is linted and tested and that they don't contain secrets.

          Fix the pre-commit hook issues instead of bypassing them.GPG signing needs user to approve an interactive popup. If it fails you need to try again.

          Ask input from user if you get blocked and never use these flags unless when explicitly allowed by the user!

          You are not allowed to use SKIP variable before git commit to skip hooks:
          ```
          SKIP=... git commit -m "..."
          ```

          ## Pushing git

          Do not push git commits unless when user allowed it.

          Use `git push origin HEAD` instead of just `git push` to avoid pushing all local branches.

          ## Failing github actions

          If github actions fail for a temporary issues don't create custom overlays.
          Instead rerun them first to see if it would fix them:

          ```sh
          gh run rerun <id>
          ```

          ## Adding custom tools, dependencies or git hooks

          If project needs tools which are not yet installed ensure that `devenv.nix` exists in the project.

          If it doesn't exist you need to run: `devenv init` first.

          Then add the required tools or git hooks to `devenv.nix`.

          ## Installing git hooks

          Always install git hooks into the devenv.nix

          ## Cargo documents
          Do not use `--open` flag with `cargo doc`

          ## Prefer libraries to fix html entities and encoding issues
          This is terrible (manual replacements):
          ```rust
          let unescaped = trimmed
              .replace("&lt;", "<")
              .replace("&gt;", ">")
              .replace("&quot;", "\"")
              .replace("&amp;", "&")
              .replace("&#39;", "'")
              .replace("&apos;", "'");
          ```

          This is great (using htmlescape library):
          ```rust
          let unescaped = match htmlescape::decode_html(trimmed) {
              Ok(decoded) => decoded,
              Err(_) => trimmed.to_string(),
          };
          ```
        '';
      };
    };
}
