{
  username,
  pkgs,
  lib,
  ...
}:
let
  manifest = builtins.fromJSON (builtins.readFile ./src/manifest.json);

  google-keyboard-nav-crx = pkgs.stdenv.mkDerivation {
    pname = "google-keyboard-nav";
    version = manifest.version;
    src = ./src;
    nativeBuildInputs = [ pkgs.go-crx3 ];

    buildPhase = ''
            runHook preBuild

            # Copy source to writable directory (nix store is read-only)
            mkdir -p build
            cp -r $src/* build/

            # Pack as CRX3 with our PEM key
            crx3 pack build -p ${./extension.pem} -o extension.crx

            # Extract extension ID from the CRX
            EXTID=$(crx3 id extension.crx)
            echo "Extension ID: $EXTID"

            # Create Chrome update manifest XML
            # Chrome fetches this to discover the CRX location and version
            cat > update.xml <<XMLEOF
      <?xml version='1.0' encoding='UTF-8'?>
      <gupdate xmlns='http://www.google.com/update2/response' protocol='2.0'>
        <app appid='$EXTID'>
          <updatecheck codebase='file://$out/extension.crx' version='${manifest.version}'/>
        </app>
      </gupdate>
      XMLEOF

            # Create external extension JSON for Chrome
            cat > external-extension.json <<JSONEOF
      {"external_update_url": "file://$out/update.xml"}
      JSONEOF

            echo -n "$EXTID" > extension_id.txt

            runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp extension.crx $out/
      cp update.xml $out/
      cp external-extension.json $out/
      cp extension_id.txt $out/
      runHook postInstall
    '';
  };

  extDir = "/Library/Application Support/Google/Chrome/External Extensions";
in
{
  # NOTE: nix-darwin only runs preActivation, postActivation, or extraActivation.
  # Custom activation script names are silently ignored.
  system.activationScripts.postActivation.text = ''
    echo "Installing google-keyboard-nav Chrome extension (CRX3)..."
    EXTID=$(cat ${google-keyboard-nav-crx}/extension_id.txt)
    mkdir -p "${extDir}"
    cp ${google-keyboard-nav-crx}/external-extension.json "${extDir}/$EXTID.json"
    chmod 644 "${extDir}/$EXTID.json"

    # Clean up old unpacked extension deployment
    rm -rf "/Users/${username}/.config/google-keyboard-nav"
  '';
}
