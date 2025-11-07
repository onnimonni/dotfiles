{ pkgs, ... }:
{
  environment.systemPackages = [
    # Sometimes irb is pretty nice
    pkgs.ruby
  ];

  home-manager.users.onnimonni.home.file = {
    ".gemrc".text = ''
      # Don't intall documentation for gems
      gem: --no-document
    '';
  };
}
