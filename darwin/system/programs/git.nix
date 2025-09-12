{ pkgs, config, ... }:
{
  home-manager.users.${config.system.primaryUser} = { pkgs, ... }: {
    programs.git = {
      enable = true;

      attributes = [ "*.lockb binary diff=lockb" ];

      extraConfig = {
        commit.gpgsign = true;

        diff.lockb = {
          textconv = "bun";
          binary = true;
        };

        core = {
          editor = "nvim";
          autocrlf = false;
          quotePath = false;
        };

        push.default = "simple";
        pull.rebase = true;
        fetch.prune = true;
        branch.autosetuprebase = "always";
        init.defaultBranch = "main";
        rerere.enabled = true;
        color.ui = true;

        blame.date = "relative";

        "color \"diff-highlight\"" = {
          oldNormal = "red bold";
          oldHighlight = "red bold";
          newNormal = "green bold";
          newHighlight = "green bold ul";
        };

        "color \"diff\"" = {
          meta = "yellow";
          frag = "magenta bold";
          commit = "yellow bold";
          old = "red bold";
          new = "green bold";
          whitespace = "red reverse";
        };
      };

      delta.enable = true;
    };
  };
}
