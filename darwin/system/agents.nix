{
  pkgs,
  lib,
  inputs,
  username,
  fullName,
  email,
  ...
}:
{
  # Home-manager configuration for agents
  home-manager.users.${username} = {
    home.file = {
      ".agents/AGENTS.md".text = ''
        IMPORTANT: In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

        My name is ${fullName} and my nickname is ${username}. Use ${email} in emails.

        ## GitHub

        - Your primary method for interacting with GitHub should be the GitHub CLI (gh).

        ### Viewing private issue attachments
        To view attachments from private repository issues:

        ```sh
        gh api -H "Accept: application/octet-stream" \
          "https://github.com/user-attachments/assets/32c11c1a-3afb-48ec-8fb6-9d95ed8d4d96" > /tmp/issue-53.png 2>&1
        ```

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

        **IMPORTANT: You are never allowed to use `--no-verify` in git commits**

        Git commit hooks verify that code is linted and tested and that they don't contain secrets.

        Fix the pre-commit hook issues instead of bypassing them.

        **Always use `--no-gpg-sign` flag in git commits** to skip GPG signing.

        Ask input from user if you get blocked and never use `--no-verify` unless when explicitly allowed by the user!

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

        ## Use sd instead of sed
        Use `sd` for find & replace instead of `sed`. It's simpler and more intuitive:

        ```sh
        # sed: confusing syntax with -i, escaping, delimiters
        sed -i 's/before/after/g' file.txt

        # sd: simple and intuitive
        sd 'before' 'after' file.txt
        ```

        sd uses regex by default. For literal strings use `-F`:
        ```sh
        sd -F 'literal.string' 'replacement' file.txt
        ```

        ## Cargo documents
        Do not use `--open` flag with `cargo doc`

        ## Rust Build Performance

        - **Use `cargo check`** for 90% of dev work (skips codegen/linking, 10x faster)
        - **Never use full `lto = true`** in release - use `lto = "thin"` instead (20-30% faster builds)
        - **Strip debug from deps** in `.cargo/config.toml`:
          ```toml
          [profile.dev.package."*"]
          debug = false
          strip = true
          ```
        - Monitor target/ size - if >5GB, run cargo clean (stale artifacts accumulate)
        - Use lld linker on Linux for 2-5x faster linking (add to devenv.nix)
        - macOS: ld64 is already fast, don't configure custom linker

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
