{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = [
    pkgs.claude-code
  ];

  # Create a home activation script to login enable MCP servers for claude code.
  home.activation = {
    configureClaudeMCP = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Configuring Claude MCP servers..."

      echo "Configuring Githits..."
      ${pkgs.claude-code}/bin/claude mcp get GitHits > /dev/null 2>&1 || \
        ${pkgs.claude-code}/bin/claude mcp add \
          --transport http \
          GitHits \
          --scope user \
          https://mcp.githits.com/ \
          --header "Authorization: Bearer $(cat ${osConfig.sops.secrets.githits_api_key.path})"

      echo "Configuring Context7..."
      ${pkgs.claude-code}/bin/claude mcp get context7 > /dev/null 2>&1 || \
        ${pkgs.claude-code}/bin/claude mcp add \
          --transport http \
          context7 \
          --scope user \
          https://mcp.context7.com/mcp \
          --header "CONTEXT7_API_KEY: $(cat ${osConfig.sops.secrets.context7_api_key.path})"
    '';
  };

  home.file = {
    # See more in https://docs.claude.com/en/docs/claude-code/settings
    # These were needed to compile large C-programs like duckdb
    ".claude/settings.json".text = ''
      {
        "env": {
          "BASH_DEFAULT_TIMEOUT_MS": "1800000",
          "BASH_MAX_TIMEOUT_MS": "3600000"
        }
      }
    '';

    # Global instructions for Claude Code
    ".claude/CLAUDE.md".text = ''
      IMPORTANT: In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

      ## GitHub

      - Your primary method for interacting with GitHub should be the GitHub CLI (gh).

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

      ## DuckDB

      You can enable timer by running `.timer on` command in duckdb sql script.

      You can't echo in duckdb scripts. This doesn't work:

      ```sql
      .echo Done!
      ```

      Instead you need to:

      ```sql
      SELECT "Done!" as status
      ```

      ## Failing git commit

      **IMPORTANT: You are never allowed to use: `--no-verify` or `--no-gpg-sign` in git commits**

      Git commit hooks verify that code is linted and tested and that they don't contain secrets.

      Fix the pre-commit hook issues instead of bypassing them.GPG signing needs user to approve an interactive popup. If it fails you need to try again.

      Ask input from user if you get blocked and never use these flags unless when explicitly allowed by the user!

      Also don't try to skip hooks with certain env like:
      ```
      SKIP=mix-test
      ```

      ## Pushing git

      Do not push git commits unless when user allowed it.

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
    '';
  };
}
