{
  pkgs,
  username,
  ...
}:
let
  scrollerConfig = {
    defaults = {
      scrollAmount = 400;
      continuousSpeed = 5;
      mouseXRatio = 0.75;
      mouseYRatio = 0.5;
      continuousIntervalMs = 16;
      holdThresholdMs = 500;
    };
    apps = { };
  };

  configJson = pkgs.writeText "smooth-scroller-config.json" (builtins.toJSON scrollerConfig);

  smooth-scroller = pkgs.swiftPackages.stdenv.mkDerivation {
    pname = "smooth-scroller";
    version = "0.1.0";
    src = ./src;

    nativeBuildInputs = [ pkgs.swiftPackages.swift ];

    buildPhase = ''
      swiftc -O -o smooth-scroller main.swift
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp smooth-scroller $out/bin/
    '';

    meta = {
      description = "Keyboard-triggered smooth scroll tool for macOS";
      platforms = pkgs.lib.platforms.darwin;
    };
  };
in
{
  environment.systemPackages = [ smooth-scroller ];

  system.activationScripts.configureSmoothScroller.text = ''
    echo "Deploying smooth-scroller config..."
    mkdir -p /Users/${username}/.config/smooth-scroller
    cp ${configJson} /Users/${username}/.config/smooth-scroller/config.json
    chmod 644 /Users/${username}/.config/smooth-scroller/config.json
    chown ${username}:staff /Users/${username}/.config/smooth-scroller/config.json
  '';
}
