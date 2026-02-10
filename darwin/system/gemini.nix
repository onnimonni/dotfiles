{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
{
  # Install Google AI tools via homebrew cask
  homebrew.casks = [
    "antigravity"
    "gemini"
  ];

  # Home-manager configuration for gemini
  home-manager.users.${username} = {
    home.file = {
      ".gemini/GEMINI.md".text = ''
        # More instructions in
        @~/.agents/AGENTS.md
      '';
    };
  };
}
