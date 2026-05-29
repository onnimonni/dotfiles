{ ... }:
{
  # zsh used by GUI apps (e.g. Antigravity, VS Code tasks) that spawn
  # /bin/zsh non-interactively. Only /etc/zshenv runs in that case, so
  # PATH setup must live in shellInit (which nix-darwin writes there).
  programs.zsh = {
    enable = true;

    shellInit = ''
      # Expose Homebrew binaries (e.g. gh) to GUI-launched non-interactive shells
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
  };
}
