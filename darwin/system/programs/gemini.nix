{ pkgs, ... }:
{
  #environment.systemPackages = with pkgs; [
  #  gemini-cli
  #];
  homebrew.brews = [
    # Homebrew has usually newer gemini-cli than nix
    "gemini-cli"
  ];
}
