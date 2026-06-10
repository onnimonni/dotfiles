{ pkgs, lib, ... }:
let
  # Extensions with no registered UTI -> macOS makes dyn.* UTIs that duti
  # cannot bind. Use LaunchServices LSHandlers with
  # LSHandlerContentTagClass = "public.filename-extension" instead, which
  # binds by extension directly. Bundle IDs must be lower-case to match
  # what `lsregister` stores.
  extHandlers = {
    "com.microsoft.vscode" = [
      "ex"
      "exs"
      "tf"
      "test"
    ];
  };

  extHandlersJson = builtins.toJSON extHandlers;
in
{
  home.packages = [
    pkgs.duti
  ];

  # Create a home activation script to apply duti settings
  home.activation = {
    setFileAssociation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting file associations with duti..."
      ${pkgs.duti}/bin/duti ~/.duti.conf

      echo "Setting file associations via LSHandlers for extensions without UTIs..."
      PLIST="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
      TMP="$(mktemp -t lshandlers.XXXXXX.json)"
      TMP_NEW="$TMP.new"

      if [ -f "$PLIST" ]; then
        /usr/bin/plutil -convert json -o "$TMP" "$PLIST"
      else
        mkdir -p "$(dirname "$PLIST")"
        echo '{"LSHandlers":[]}' > "$TMP"
      fi

      ${pkgs.jq}/bin/jq \
        --argjson map '${extHandlersJson}' '
        ( [ $map | to_entries[] | .key as $bid | .value[] | { bid: $bid, ext: . } ] ) as $desired
        | .LSHandlers = (
            ( (.LSHandlers // []) | map(
                select(
                  (.LSHandlerContentTagClass // "") != "public.filename-extension"
                  or ( [ .LSHandlerContentTag ] | inside( [ $desired[].ext ] ) | not )
                )
              )
            )
            + ( $desired | map({
                LSHandlerContentTag: .ext,
                LSHandlerContentTagClass: "public.filename-extension",
                LSHandlerRoleAll: .bid
              }) )
          )
      ' "$TMP" > "$TMP_NEW"

      /usr/bin/plutil -convert binary1 -o "$PLIST" "$TMP_NEW"
      rm -f "$TMP" "$TMP_NEW"

      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -kill -r -domain local -domain system -domain user >/dev/null 2>&1 || true
    '';
  };
  home.file = {
    ".duti.conf".text = ''
      # Open links in Finicky
      se.johnste.finicky http
      se.johnste.finicky com.apple.default-app.web-browser

      # VLC
      org.videolan.vlc mkv all
      org.videolan.vlc mp4 all
      org.videolan.vlc avi all
      org.videolan.vlc mp3 all
      org.videolan.vlc mov all
      org.videolan.vlc wav all
      org.videolan.vlc flac all
      org.videolan.vlc ogg all
      org.videolan.vlc webm all
      org.videolan.vlc webp all

      # VS Code (only UTIs / extensions macOS already knows about)
      com.microsoft.VSCode public.source-code	all
      com.microsoft.VSCode public.plain-text all
      com.microsoft.VSCode .xml all
      com.microsoft.VSCode .md all
      # .ex .exs .tf .test handled via LSHandlers in setFileAssociation above
    '';
  };
}
