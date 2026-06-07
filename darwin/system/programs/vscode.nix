{
  pkgs,
  lib,
  username,
  ...
}:
{
  # VS Code .app + `code` CLI installed via homebrew cask `visual-studio-code`
  # (see homebrew.nix). home-manager only writes user settings — the package is
  # stubbed so nothing gets linked into ~/Applications/Home Manager Apps (which
  # would cause Finder to spam /Applications with "Visual Studio Code alias N" files).
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.runCommand "vscode-stub" { } "mkdir -p $out";

      profiles.default.userSettings = {
        "editor.accessibilitySupport" = "off";
        "window.zoomLevel" = 2;
        "keyboard.dispatch" = "keyCode";
        "workbench.startupEditor" = "none";
        "svelte.enable-ts-plugin" = true;
        "workbench.editor.enablePreview" = false;
        "[python]" = {
          "editor.formatOnType" = true;
        };
        "[json]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "editor.minimap.enabled" = false;
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "window.autoDetectColorScheme" = true;
        "[javascript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "[svelte]" = {
          "editor.defaultFormatter" = "svelte.svelte-vscode";
        };
        "git.openRepositoryInParentFolders" = "never";
        "[elixir]" = {
          "editor.defaultFormatter" = "lexical-lsp.lexical";
        };
        "[nix]" = {
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
        "continue.showInlineTip" = false;
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "makefile.configureOnOpen" = false;
        "files.associations" = {
          ".env*" = "plaintext";
        };
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = false;
        };
        "files.exclude" = {
          "**/.direnv" = true;
          "**/.devenv" = true;
        };
        "search.exclude" = {
          "**/.direnv" = true;
          "**/.devenv" = true;
        };
        "github.copilot.advanced" = { };
        "workbench.editorAssociations" = {
          "*.copilotmd" = "vscode.markdown.preview.editor";
          "*.plist" = "default";
        };
        "lexical.trace.server" = "messages";
        "lexical.server.releasePathOverride" = "\${userHome}/.dotfiles/bin/expert";
        "workbench.editor.empty.hint" = "hidden";
        "github.copilot.nextEditSuggestions.enabled" = true;
      };
    };
  };
}
