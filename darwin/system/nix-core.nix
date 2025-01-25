# Custom nix rules to use determinate nix installer with nix-darwin
{
  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = true;
    # run on zeroeth day each week
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 7d";
  };

  nix.settings = {
    # Disable auto-optimise-store because of this issue:
    #   https://github.com/NixOS/nix/issues/7273
    # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
    auto-optimise-store = false;
    ssl-cert-file = "/private/etc/nix/macos-keychain.crt";

    extra-trusted-substituters = [
      "https://cache.flakehub.com"
    ];
  };
}