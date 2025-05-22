{ pkgs, ... }:
{
  environment.systemPackages = [
    # Sometimes irb is pretty nice
    pkgs.ruby
  ];

  home-manager.users.onnimonni.home.file = {
    ".gemrc".text = ''
      # Don't intall documentation and install binaries to my home folder
      gem: --no-document
    '';
  };
}
