# Local DNS ad/tracker blocking (Pi-hole equivalent) with blocky.
#
# - blocky: root launchd daemon on 127.0.0.1:53. hagezi Multi PRO blocklist,
#   encrypted (DoH) upstreams; fallback DNS bypasses encryption and blocking.
# - networking.dns: nix-darwin points every known network service at
#   127.0.0.1, then 8.8.8.8 on each `darwin-rebuild switch`.
# - blocky-captive-guard: root launchd daemon, polls every 15s (+ on resolver
#   change). Probes http://captive.apple.com/hotspot-detect.html through the
#   DHCP-provided DNS (bypassing blocky) and checks blocky itself can resolve.
#     * portal page                         -> system DNS = DHCP (passthrough)
#     * blocky cannot resolve               -> system DNS = 8.8.8.8
#     * "Success" AND blocky works           -> system DNS = 127.0.0.1, 8.8.8.8
#     * probe inconclusive, blocky works     -> leave as is
#   Covers captive portals and networks that block DoH. Only calls
#   networksetup when the state actually changes.
# - `adblock on|off [duration]|status|log`: manual override via blocky's
#   REST API on 127.0.0.1:4000.
#
# Browser-level blocking (uBlock Origin) still needed for same-origin ads
# such as YouTube; DNS cannot separate those.
{ pkgs, lib, ... }:
let
  # Services nix-darwin and the guard may configure. nix-darwin and the guard
  # both skip names that do not exist on the machine, so this can be a
  # superset. VPN services intentionally excluded: they push their own DNS.
  dnsServices = [
    "Wi-Fi"
    "Ethernet"
    "Thunderbolt Ethernet"
    "USB 10/100/1000 LAN"
    "USB 10/100 /1000LAN"
  ];

  localDns = "127.0.0.1";
  fallbackDns = "8.8.8.8";
  systemDns = [
    localDns
    fallbackDns
  ];
  httpPort = 4000;

  blockyConfig = (pkgs.formats.yaml { }).generate "blocky.yml" {
    upstreams = {
      groups.default = [
        "https://dns.quad9.net/dns-query"
        "https://cloudflare-dns.com/dns-query"
      ];
      strategy = "parallel_best";
      timeout = "2s";
      # Start serving even if upstreams unreachable at boot.
      init.strategy = "fast";
    };
    # Plain DNS by IP only for resolving the DoH hostnames above.
    bootstrapDns = [
      { upstream = "tcp+udp:9.9.9.9"; }
      { upstream = "tcp+udp:1.1.1.1"; }
    ];
    blocking = {
      denylists.ads = [
        # ~230k wildcard entries. Alternatives: wildcard/light.txt (less
        # aggressive), wildcard/ultimate.txt (more). Same repo.
        "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt"
      ];
      clientGroupsBlock.default = [ "ads" ];
      blockType = "zeroIp";
      blockTTL = "1m";
      loading = {
        # Short so a boot without network still gets lists soon after.
        refreshPeriod = "4h";
        strategy = "fast";
        downloads = {
          timeout = "60s";
          attempts = 5;
          cooldown = "10s";
        };
      };
    };
    caching = {
      minTime = "5m";
      maxTime = "30m";
      prefetching = true;
    };
    ports = {
      dns = "${localDns}:53";
      http = "${localDns}:${toString httpPort}";
    };
    log.level = "warn";
  };

  # Decides whether system DNS should point at blocky or at DHCP. Stateless:
  # current state is read back from networksetup each run.
  captiveGuard = pkgs.writeShellScript "blocky-captive-guard" ''
    set -u
    PATH=/usr/bin:/bin:/usr/sbin:/sbin

    LOCAL_DNS=${localDns}
    FALLBACK_DNS=${fallbackDns}
    PROBE_HOST=captive.apple.com
    PROBE_URL="http://$PROBE_HOST/hotspot-detect.html"
    EXPECT='<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>'
    SERVICES=(${lib.escapeShellArgs dnsServices})
    DRY_RUN="''${BLOCKY_GUARD_DRY_RUN:-}"

    log() { echo "$(date '+%F %T') $*"; }

    iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
    if [ -z "$iface" ]; then
      [ -n "$DRY_RUN" ] && log "no default route; leaving DNS unchanged"
      exit 0
    fi
    dhcp_dns=$(ipconfig getoption "$iface" domain_name_server 2>/dev/null | head -n1)
    probe_dns="''${dhcp_dns:-$FALLBACK_DNS}"

    # 1. Internet / portal probe through DHCP DNS, never through blocky.
    probe=unknown
    probe_ip=$(dig +short +time=2 +tries=1 @"$probe_dns" "$PROBE_HOST" A 2>/dev/null \
      | grep -E '^[0-9]+(\.[0-9]+){3}$' | head -n1)
    if [ -n "$probe_ip" ]; then
      body=$(curl -s -m 5 --noproxy '*' --resolve "$PROBE_HOST:80:$probe_ip" "$PROBE_URL" 2>/dev/null)
      rc=$?
      if [ $rc -eq 0 ]; then
        if [ "$body" = "$EXPECT" ]; then probe=success; else probe=portal; fi
      fi
    fi

    # 2. Can blocky itself resolve through its encrypted upstreams?
    blocky_ok=0
    if dig +short +time=2 +tries=1 @"$LOCAL_DNS" "$PROBE_HOST" A 2>/dev/null \
        | grep -qE '^[0-9]+(\.[0-9]+){3}$'; then
      blocky_ok=1
    fi

    case "$probe:$blocky_ok" in
      success:1) want=local ;;
      portal:*)  want=dhcp ;;
      *:0)       want=fallback ;; # also recover when the portal probe fails
      *)
        [ -n "$DRY_RUN" ] && log "no connectivity via $dhcp_dns; leaving DNS unchanged"
        exit 0
        ;;
    esac
    [ -n "$DRY_RUN" ] && log "iface=$iface dhcp_dns=$dhcp_dns probe=$probe blocky_ok=$blocky_ok -> want=$want"

    case "$want" in
      local) desired_dns=("$LOCAL_DNS" "$FALLBACK_DNS") ;;
      fallback) desired_dns=("$FALLBACK_DNS") ;;
      dhcp) desired_dns=(Empty) ;;
    esac
    desired=$(printf '%s\n' "''${desired_dns[@]}")
    all_services=$(networksetup -listallnetworkservices 2>/dev/null)
    for svc in "''${SERVICES[@]}"; do
      printf '%s\n' "$all_services" | grep -Fxq "$svc" || continue
      current=$(networksetup -getdnsservers "$svc" 2>/dev/null) || continue
      [[ "$current" = "There aren't any DNS Servers set on "* ]] && current=Empty
      [ "$current" = "$desired" ] && continue
      cur=$(printf '%s' "$current" | tr '\n' ',')
      if [ -n "$DRY_RUN" ]; then
        log "would set $svc: $cur -> $want"
        continue
      fi
      networksetup -setdnsservers "$svc" "''${desired_dns[@]}" || continue
      log "$svc DNS: $cur -> $want (probe=$probe blocky_ok=$blocky_ok)"
    done
  '';

  adblock = pkgs.writeShellScriptBin "adblock" ''
    set -euo pipefail
    api="http://${localDns}:${toString httpPort}/api/blocking"
    case "''${1:-status}" in
      status)
        printf 'blocking: '; curl -sf "$api/status"; echo
        for svc in ${lib.escapeShellArgs dnsServices}; do
          /usr/sbin/networksetup -getdnsservers "$svc" 2>/dev/null \
            | grep -q '^${localDns}$' && echo "$svc: DNS -> blocky" || true
        done
        ;;
      off) curl -sf "$api/disable?duration=''${2:-10m}" && echo "blocking off for ''${2:-10m}" ;;
      on)  curl -sf "$api/enable" && echo "blocking on" ;;
      log) tail -n 50 /var/log/blocky.log /var/log/blocky-captive-guard.log ;;
      check) sudo env BLOCKY_GUARD_DRY_RUN=1 ${captiveGuard} ;;
      *) echo "usage: adblock [status|on|off [10m]|log|check]" >&2; exit 2 ;;
    esac
  '';
in
{
  environment.systemPackages = [
    pkgs.blocky
    adblock
  ];

  networking.knownNetworkServices = dnsServices;
  networking.dns = systemDns;

  launchd.daemons.blocky = {
    serviceConfig = {
      Label = "org.blocky.dns";
      # launchd runs before the /nix volume mounts. The initial executable
      # must be on the system volume, or launchd can get stuck at EX_CONFIG.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''/bin/wait4path "$1" && /bin/wait4path "$3" && exec "$@"''
        "blocky"
        "${pkgs.blocky}/bin/blocky"
        "--config"
        "${blockyConfig}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/blocky.log";
      StandardErrorPath = "/var/log/blocky.log";
    };
  };

  launchd.daemons.blocky-captive-guard = {
    serviceConfig = {
      Label = "org.blocky.captive-guard";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''/bin/wait4path "$1" && exec "$@"''
        "blocky-captive-guard"
        "${captiveGuard}"
      ];
      RunAtLoad = true;
      StartInterval = 15;
      # configd rewrites this on resolver changes (network join, VPN, DHCP).
      WatchPaths = [ "/private/var/run/resolv.conf" ];
      StandardOutPath = "/var/log/blocky-captive-guard.log";
      StandardErrorPath = "/var/log/blocky-captive-guard.log";
    };
  };
}
