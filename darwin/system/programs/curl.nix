{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.curl
  ];

  home-manager.users.onnimonni.home.file = {
    ".curlrc".text = ''
      # Enable redirect
      -L

      # Disguise as Safari browser.
      user-agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"

      # When following a redirect, automatically set the previous URL as referer.
      referer = ";auto"

      # Wait 60 seconds before timing out.
      connect-timeout = 60
    '';
  };
}
