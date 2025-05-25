{ pkgs, ... }:
{
  homebrew.casks = [
    # MITMProxy for debugging HTTP traffic
    # Not sure if this actually needs to be installed as casks but we do need the
    # Mitmproxy Redirector app and it probably only comes from cask?
    "mitmproxy"
  ];

  home-manager.users.onnimonni.home.file = {
    ".mitmproxy/keys.yaml".text = ''
      # See more: https://github.com/mitmproxy/mitmproxy/issues/2649#issuecomment-392342343
      # Copy request to clipboard as curl.
      - key: c
        cmd: export.clip curl @focus
    '';
  };
}
