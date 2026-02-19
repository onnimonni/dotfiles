{
  pkgs,
  username,
  ...
}:
let
  scrollerConfig = {
    defaults = {
      # All speeds are in px per 8ms tick (~120fps).
      # Multiply by 125 to get px/sec (e.g. 8.0 = 1000 px/s).
      initialSpeed = 5.0; # px/tick (~625 px/s). 0 = auto from window height
      maxSpeed = 48.0; # speed cap (~6000 px/s)
      acceleration = 0.002; # multiplicative factor per tick: speed *= (1 + 0.002)
      coastMs = 800; # ms at constant initial speed before acceleration begins
      mouseXRatio = 0.75;
      mouseYRatio = 0.5;
    };
    apps = { };
  };

  configJson = pkgs.writeText "smooth-scroller-config.json" (builtins.toJSON scrollerConfig);

  # FIXME: Build logs show "Segmentation fault: 11" in audit-tmpdir.sh during fixupPhase.
  # audit-tmpdir uses ELF-specific tooling (isELF/patchelf) that segfaults on Mach-O binaries.
  # Doesn't affect the output binary. https://github.com/NixOS/nixpkgs/issues/54515
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
