Read and follow @CLAUDE.md

## New File Policy
> [!IMPORTANT]
> Whenever you create a new `.nix` file, you MUST add it to git staging immediately using `git add <file>`. Nix-darwin will not see untracked files and builds will fail with "No such file or directory" or "file '...' not found in the Nix store".