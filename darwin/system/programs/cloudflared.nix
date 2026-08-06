# Cloudflare Tunnel for sharing the Mac Studio over SSH + VNC + Eternal Terminal.
# - Server side (Mac Studio): runs cloudflared as a launchd daemon, etserver as
#   a launchd daemon, hardens sshd to key-only, pulls GitHub pubkeys, and
#   disables sleep on AC.
# - Client side (anything else): adds an `ssh mac-studio` host using
#   `cloudflared access ssh` as ProxyCommand, plus an `et-mac-studio` wrapper
#   that spawns a one-shot `cloudflared access tcp` listener for ET's TCP leg.
# Active only when `shareMacDomain` is set in the flake user configuration.
{
  pkgs,
  lib,
  username,
  hostname,
  shareMacDomain ? null,
  ...
}:
let
  isMacStudio = hostname == "Onnis-Mac-Studio";
  enabled = shareMacDomain != null;
  serverEnabled = enabled && isMacStudio;
  clientEnabled = enabled && !isMacStudio;

  authorizedKeys = lib.filter (k: k != "" && !(lib.hasPrefix "#" k)) (
    lib.splitString "\n" (lib.fileContents ../../../share-mac/github-onnimonni-keys.pub)
  );

  configRendered =
    if enabled then
      builtins.replaceStrings [ "@DOMAIN@" ] [ shareMacDomain ] (
        lib.fileContents ../../../share-mac/cloudflared-config.yml.example
      )
    else
      "";

  # Wrapper for ET clients. ET's bootstrap uses ssh (one-shot cloudflared
  # access ssh through %h substitution), and its long-lived TCP leg goes
  # through a temporary cloudflared access tcp listener on a fixed loopback
  # port. Both cloudflared invocations are foreground subprocesses tied to
  # the lifetime of this script — no launchd, no background services.
  etMacStudioWrapper = pkgs.writeShellScriptBin "et-mac-studio" ''
    set -euo pipefail
    DOMAIN=${lib.escapeShellArg shareMacDomain}
    USER_=${lib.escapeShellArg username}
    LOCAL_PORT=2022
    LOG=$(mktemp)
    trap 'rm -f "$LOG"' EXIT

    # Refuse if local port is busy (e.g. concurrent et session).
    if ${pkgs.netcat}/bin/nc -z 127.0.0.1 "$LOCAL_PORT" 2>/dev/null; then
      echo "et-mac-studio: 127.0.0.1:$LOCAL_PORT already in use" >&2
      exit 1
    fi

    "${pkgs.cloudflared}/bin/cloudflared" access tcp \
      --hostname "et-mac.$DOMAIN" \
      --url "127.0.0.1:$LOCAL_PORT" >"$LOG" 2>&1 &
    TUNNEL_PID=$!
    trap 'kill $TUNNEL_PID 2>/dev/null || true; rm -f "$LOG"' EXIT

    # Wait for listener (cloudflared can take a second to come up).
    for _ in $(seq 1 50); do
      if ${pkgs.netcat}/bin/nc -z 127.0.0.1 "$LOCAL_PORT" 2>/dev/null; then
        break
      fi
      sleep 0.1
    done
    if ! ${pkgs.netcat}/bin/nc -z 127.0.0.1 "$LOCAL_PORT" 2>/dev/null; then
      echo "et-mac-studio: cloudflared tcp listener never came up" >&2
      cat "$LOG" >&2
      exit 1
    fi

    # ET host = 127.0.0.1:LOCAL_PORT (et's TCP destination).
    # ssh bootstrap is redirected to ssh-mac.$DOMAIN via --ssh-option.
    exec "${pkgs.eternal-terminal}/bin/et" \
      "$USER_@127.0.0.1:$LOCAL_PORT" \
      --ssh-option "HostName=ssh-mac.$DOMAIN" \
      --ssh-option "ProxyCommand=${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h" \
      "$@"
  '';
in
{
  environment.systemPackages =
    lib.optionals enabled [
      pkgs.cloudflared
      pkgs.eternal-terminal
    ]
    ++ lib.optionals clientEnabled [ etMacStudioWrapper ];

  # ---- Mac Studio (server) ----

  # sshd hardening drop-in. 99-max-auth-tries.conf already sets MaxAuthTries 10
  # for Secretive; we layer key-only on top.
  # Note: ListenAddress is intentionally absent — macOS launchd socket-activates
  # sshd with the listen socket already bound on `*:22`, so any ListenAddress
  # directive here would be a silent no-op. LAN exposure is acceptable because
  # the home router doesn't forward inbound 22 and only onnimonni's keys work.
  environment.etc."ssh/sshd_config.d/100-share-mac.conf" = lib.mkIf serverEnabled {
    text = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      ChallengeResponseAuthentication no
      PermitRootLogin no
      AllowUsers ${username}
      ClientAliveInterval 60
      ClientAliveCountMax 3
    '';
  };

  # GitHub pubkeys -> /etc/ssh/nix_authorized_keys.d/<user> via the existing
  # 101-authorized-keys.conf AuthorizedKeysCommand.
  users.users.${username}.openssh.authorizedKeys.keys = lib.mkIf serverEnabled authorizedKeys;

  # Tunnel config. Credentials JSON is placed manually after `tunnel create`.
  environment.etc."cloudflared/config.yml" = lib.mkIf serverEnabled {
    text = configRendered;
  };

  launchd.daemons.cloudflared = lib.mkIf serverEnabled {
    serviceConfig = {
      Label = "com.cloudflare.cloudflared";
      ProgramArguments = [
        "${pkgs.cloudflared}/bin/cloudflared"
        "--no-autoupdate"
        "tunnel"
        "--config"
        "/etc/cloudflared/config.yml"
        "run"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/cloudflared.log";
      StandardErrorPath = "/var/log/cloudflared.err.log";
    };
  };

  # Eternal Terminal server. Listens on TCP 2022. etserver has no built-in
  # bind-address flag (MisterTea/EternalTerminal#587) so it binds 0.0.0.0;
  # LAN exposure is acceptable for the same reasons as sshd above (home
  # router doesn't forward, ET still requires ssh auth to bootstrap).
  launchd.daemons.etserver = lib.mkIf serverEnabled {
    serviceConfig = {
      Label = "com.mistertea.etserver";
      ProgramArguments = [
        "${pkgs.eternal-terminal}/bin/etserver"
        "--port"
        "2022"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/etserver.log";
      StandardErrorPath = "/var/log/etserver.err.log";
    };
  };

  # Stay reachable on AC. Idempotent, fine to re-run on every boot.
  launchd.daemons."share-mac-pmset" = lib.mkIf serverEnabled {
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      ProgramArguments = [
        "/usr/bin/pmset"
        "-c"
        "sleep"
        "0"
        "displaysleep"
        "10"
        "tcpkeepalive"
        "1"
        "womp"
        "1"
      ];
    };
  };

  # ---- MacBook / other clients ----

  home-manager.users.${username}.programs.ssh.settings = lib.mkIf clientEnabled {
    "mac-studio" = {
      HostName = "ssh-mac.${shareMacDomain}";
      User = username;
      ProxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      ServerAliveInterval = 30;
    };
  };
}
