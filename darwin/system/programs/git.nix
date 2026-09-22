{ pkgs, config, ... }:
{
  home-manager.users.${config.system.primaryUser} = { pkgs, ... }: {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.git = {
      enable = true;

      attributes = [ "*.lockb binary diff=lockb" ];

      settings = {
        user = {
          name = "Onni Hakala";
          email = "onni@flaky.build";
          # Sign with the Secretive-backed SSH key, not GPG (no gpg binary installed).
          # Machine-specific file, created by .install.sh.
          signingkey = "~/.ssh/github_secretive.pub";
        };

        commit.gpgsign = true;
        tag.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";

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
    };
  };
}
