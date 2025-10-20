{ pkgs, lib, ... }:
{
  homebrew = {
    taps = [
      "onnimonni/ohsome-planet"
    ];
    brews = [
      "ohsome-planet"
    ];
  };
}
