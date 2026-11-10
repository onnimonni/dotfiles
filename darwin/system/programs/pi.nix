# pi coding agent (https://pi.dev) with the local ds4 model server
# (programs/ds4.nix) as the `ds4` provider, and `ds4-pi` to start both.
# pi writes its own settings (`pi install`, /model), so activation merges into
# ~/.pi/agent/{settings,models}.json instead of symlinking read-only files.
{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  pi = pkgs.pi-coding-agent;

  # https://github.com/jkeskikangas
  packages = [
    # One line per tool call in the transcript, full output on ctrl+o
    "npm:pi-minimum-sufficient-output"
    # Transactional multi-file edit/read tools
    "npm:pi-multiedit"
    # Claude models through the Claude Pro/Max subscription of Claude Code
    "npm:pi-claude-subscription"
  ];

  # Provider settings from https://github.com/antirez/ds4/blob/main/docs/CLIENTS.md
  contextWindow = 262144;
  ds4Provider = {
    baseUrl = "http://127.0.0.1:8000/v1";
    api = "openai-completions";
    # Placeholder, the local server has no authentication
    apiKey = "dsv4-local";
    compat = {
      supportsStore = false;
      supportsDeveloperRole = false;
      supportsReasoningEffort = true;
      supportsUsageInStreaming = true;
      maxTokensField = "max_tokens";
      supportsStrictMode = false;
      thinkingFormat = "deepseek";
      requiresReasoningContentOnAssistantMessages = true;
    };
    models = [
      {
        id = "deepseek-v4-flash";
        name = "DwarfStar Flash";
        reasoning = true;
        thinkingLevelMap = {
          off = null;
          minimal = "low";
          low = "low";
          medium = "medium";
          high = "high";
          xhigh = "xhigh";
        };
        input = [ "text" ];
        inherit contextWindow;
        maxTokens = 16384;
        cost = {
          input = 0;
          output = 0;
          cacheRead = 0;
          cacheWrite = 0;
        };
      }
    ];
  };

  # Starts ds4-server unless it already runs, then pi on the ds4 model. The
  # server is stopped on exit if this script started it, as it keeps the
  # model in memory.
  ds4-pi = pkgs.writeShellApplication {
    name = "ds4-pi";
    runtimeInputs = [
      pi
      pkgs.curl
    ];
    text = ''
      url="http://127.0.0.1:8000/v1/models"
      cache="$HOME/.cache/ds4"
      log="$HOME/Library/Logs/ds4-server.log"

      if ! curl -fsS "$url" >/dev/null 2>&1; then
        mkdir -p "$cache/kv" "$(dirname "$log")"
        echo "Starting ds4-server (log: $log)..." >&2
        ds4-server --ctx ${toString contextWindow} \
          --kv-disk-dir "$cache/kv" --kv-disk-space-mb 8192 >"$log" 2>&1 &
        server=$!
        trap 'kill "$server" 2>/dev/null || true' EXIT

        until curl -fsS "$url" >/dev/null 2>&1; do
          if ! kill -0 "$server" 2>/dev/null; then
            echo "ds4-server exited, see $log" >&2
            tail -n 20 "$log" >&2
            exit 1
          fi
          sleep 1
        done
      fi

      pi --model ds4/deepseek-v4-flash "$@"
    '';
  };
in
{
  environment.systemPackages = [
    pi
    ds4-pi
  ];

  home-manager.users.${username} = {
    home.activation.piConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${
        lib.makeBinPath [
          pi
          pkgs.nodejs
          pkgs.jq
        ]
      }:$PATH"
      piDir="$HOME/.pi/agent"
      mkdir -p "$piDir"

      models="$piDir/models.json"
      [ -s "$models" ] || echo '{}' >"$models"
      jq --argjson ds4 ${lib.escapeShellArg (builtins.toJSON ds4Provider)} \
        '.providers.ds4 = $ds4' "$models" >"$models.tmp" && mv "$models.tmp" "$models"

      # pi install adds each package to settings.json and installs it with npm
      settings="$piDir/settings.json"
      for package in ${lib.escapeShellArgs packages}; do
        if ! jq -e --arg p "$package" \
          'any((.packages // [])[]; (if type == "string" then . else .source end) == $p)' \
          "$settings" >/dev/null 2>&1; then
          pi install "$package" </dev/null || echo "pi: installing $package failed, run: pi install $package"
        fi
      done
    '';
  };
}
