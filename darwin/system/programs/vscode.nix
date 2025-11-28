{ pkgs, lib, ... }:
{
  # VS Code installed and configured via home-manager
  home-manager.users.onnimonni = {
    programs.vscode = {
      enable = true;
      # Use the darwin package for proper macOS integration
      package = pkgs.vscode;

      userSettings = {
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
