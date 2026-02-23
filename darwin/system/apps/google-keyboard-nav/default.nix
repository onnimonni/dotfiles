{
  username,
  ...
}:
let
  srcDir = ./src;
  destDir = "/Users/${username}/.config/google-keyboard-nav";
in
{
  system.activationScripts.deployGoogleKeyboardNav.text = ''
    echo "Deploying google-keyboard-nav extension..."
    mkdir -p ${destDir}
    cp ${srcDir}/manifest.json ${destDir}/manifest.json
    cp ${srcDir}/content.js ${destDir}/content.js
    cp ${srcDir}/styles.css ${destDir}/styles.css
    chmod 644 ${destDir}/manifest.json ${destDir}/content.js ${destDir}/styles.css
    chown ${username}:staff ${destDir}/manifest.json ${destDir}/content.js ${destDir}/styles.css
  '';
}
