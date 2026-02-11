{ pkgs, username, ... }:
{
  environment.systemPackages = [
    # Sometimes irb is pretty nice
    pkgs.ruby
  ];

  home-manager.users.${username}.home.file = {
    ".gemrc".text = ''
      # Don't intall documentation for gems
      gem: --no-document
    '';
  };
}
