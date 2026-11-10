# herdr agent multiplexer + devenv-agents `project` CLI and herdr plugin
# https://herdr.dev / https://github.com/wyattjoh/devenv-agents
{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  project = inputs.devenv-agents.packages.${pkgs.stdenv.hostPlatform.system}.project;
  inherit (pkgs) herdr;
  # herdr rewrites config.toml from its settings UI, so keep it mutable and
  # only seed the managed-worktree keybinding.
  worktreeKeybind = (pkgs.formats.toml { }).generate "herdr-worktree-keybind.toml" {
    keys.command = [
      {
        key = "prefix+shift+g";
        type = "pane";
        command = "project wt new";
        description = "create a project worktree";
      }
    ];
  };
in
{
  environment.systemPackages = [
    herdr
    project
  ];

  home-manager.users.${username} = {
    home.activation.herdrConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      herdrConfig="$HOME/.config/herdr/config.toml"
      mkdir -p "$(dirname "$herdrConfig")"
      if ! grep -qF 'command = "project wt new"' "$herdrConfig" 2>/dev/null; then
        { echo; cat ${worktreeKeybind}; } >> "$herdrConfig"
      fi

      # Link devenv-agents plugin; relinks when the store path changes.
      # Needs a running herdr server, otherwise run `project plugin install`.
      # `herdr status server` exits 0 either way, so match its output.
      if ${lib.getExe herdr} status server 2>/dev/null | grep -qx 'status: not running'; then
        echo "herdr not running: skipped plugin link, run 'project plugin install' after starting herdr"
      else
        PATH="${lib.makeBinPath [ herdr ]}:$PATH" ${lib.getExe' project "project"} plugin install \
          || echo "herdr plugin link failed: run 'project plugin install' after starting herdr"
      fi
    '';
  };
}
