{
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
        - Use the GitHub CLI (`gh`) for GitHub.
        - Private issue attachments: `gh api -H "Accept: application/octet-stream" "https://github.com/user-attachments/assets/<id>" > /tmp/file.png`
        - If GitHub Actions fail for temporary reasons, rerun first (`gh run rerun <id>`) instead of adding workarounds.

        ## Research
        Prefer the GitHits and context7 MCP servers over web search for up-to-date docs, libraries and code examples.

        ## Docs and plans
        - Keep existing README.md updated. Never create new markdown/doc files unless asked.
        - End each plan with a list of unresolved questions, if any. Extremely concise.

        ## Code
        - Never use `popen`/`system()`/`shell()` or similar to run commands from other languages. If unavoidable, tell me. Binaries in $PATH are only OK in bash scripts.
        - Prefer Go/Rust/Zig over Python/Node when feasible. Python: `uv run`, not `python`. Node: `bun`/`bunx`, not `node`/`npm`/`npx`.
        - Prefer libraries over hand-rolled escaping/encoding (e.g. HTML entities).
        - Shell scripts start with `#!/usr/bin/env bash`.
        - Use `sd` instead of `sed` for find & replace (`sd -F` for literal strings).

        ## Tools and git hooks
        Add missing tools and git hooks to the project's `devenv.nix` (run `devenv init` first if it doesn't exist).

        ## Git
        - Never bypass commit hooks with `--no-verify` or `SKIP=...`. Fix the issues, or ask me if blocked.
        - Always commit with `--no-gpg-sign`.
        - Don't push unless I allowed it. Use `git push origin HEAD`, not `git push`.
      '';
    };
  };
}
