{
  pkgs,
  username,
  ...
}:
let
  select-keyboard-layout = pkgs.swiftPackages.stdenv.mkDerivation {
    pname = "select-keyboard-layout";
    version = "0.1.0";
    src = ./src;

    nativeBuildInputs = [ pkgs.swiftPackages.swift ];

    buildPhase = ''
      swiftc -O -o select-keyboard-layout main.swift
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp select-keyboard-layout $out/bin/
    '';

    meta = {
      description = "Programmatically enable and select a macOS keyboard layout";
      platforms = pkgs.lib.platforms.darwin;
    };
  };

  layoutID = "org.unknown.keylayout.ONNIDVORAK-QWERTYCMD";
in
{
  environment.systemPackages = [ select-keyboard-layout ];

  # Run in user's GUI session context (launchctl asuser) so TISSelectInputSource
  # has WindowServer access. Same pattern nix-darwin uses for home-manager activation.
  system.activationScripts.selectKeyboardLayout.text = ''
    echo "Activating keyboard layout ${layoutID}..."
    launchctl asuser "$(id -u ${username})" \
      sudo -u ${username} --set-home \
      ${select-keyboard-layout}/bin/select-keyboard-layout "${layoutID}" || \
      echo "  Keyboard layout not found yet — reboot to discover new .keylayout files"
  '';
}
