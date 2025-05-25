{ pkgs, ... }:
{
  environment.systemPackages = [
    # Better ls
    pkgs.eza
  ];

  programs.fish.shellAliases = {
    ls = "eza";
    ll = "eza -l --group-directories-first";
    la = "eza -la --group-directories-first";
    l = "eza -l --group-directories-first";
  };
}
