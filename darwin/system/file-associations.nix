# Default apps, declared next to each app:
#
#   fileAssociations."abnerworks.Typora" = [ "md" "markdown" ];
#   urlHandlers."se.johnste.finicky" = [ "http" ];
#
# fileAssociations entries are either file extensions ("md") or, when they
# contain a dot, Uniform Type Identifiers covering many extensions at once
# ("public.source-code"). Routing to duti / LSHandlers happens here.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  pairs =
    attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        bid:
        map (entry: {
          inherit bid entry;
        })
      ) attrs
    );
  isUti = p: lib.hasInfix "." p.entry;
  lines = l: lib.concatStringsSep "\n" l + "\n";

  fileEntries = pairs config.fileAssociations;

  # Set one by one, skipping unchanged: macOS asks "open with X or keep Y?"
  # on every duti -s, even when nothing changes.
  dutiTsv = lines (
    map (p: "${p.bid}\t${p.entry}") (pairs config.urlHandlers)
    ++ map (p: "${p.bid}\t${p.entry}\tall") (lib.filter isUti fileEntries)
  );

  # Extensions whose system UTI belongs to an unrelated format: binding the UTI
  # would also steal its other extensions, so bind by extension only.
  extensionOnly = [
    "exs" # Elixir script vs Logic sampler UTI com.apple.logic.exs (shared with .sbk)
  ];

  # Bundle IDs must be lower-case to match what `lsregister` stores
  extensionsTsv = lines (
    map (
      p: "${lib.toLower p.bid}\t${p.entry}\t${if lib.elem p.entry extensionOnly then "ext" else "uti"}"
    ) (lib.filter (p: !isUti p) fileEntries)
  );

  appList =
    example:
    lib.mkOption {
      type = with lib.types; attrsOf (listOf str);
      default = { };
      inherit example;
    };
in
{
  options = {
    fileAssociations = appList { "abnerworks.Typora" = [ "md" ]; } // {
      description = "App bundle id -> file extensions or UTIs it opens by default.";
    };
    urlHandlers = appList { "se.johnste.finicky" = [ "http" ]; } // {
      description = "App bundle id -> URL schemes it opens by default.";
    };
  };

  config = {
    home.packages = [
      pkgs.duti
    ];

    home.activation.setFileAssociation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting file associations..."
      while IFS=$'\t' read -r bid target role; do
        [ -n "$target" ] || continue
        current="$(${pkgs.duti}/bin/duti -d "$target" 2>/dev/null || true)"
        [ "''${current,,}" = "''${bid,,}" ] || ${pkgs.duti}/bin/duti -s "$bid" "$target" $role || true
      done < ${pkgs.writeText "duti.tsv" dutiTsv}

      # Extensions with no registered UTI -> macOS makes dyn.* UTIs that duti
      # cannot bind (it exits non-zero). Bind those, and extensionOnly ones, via
      # LaunchServices LSHandlers with LSHandlerContentTagClass =
      # "public.filename-extension" instead.
      FALLBACK="$(mktemp -t lshandlers.XXXXXX.tsv)"
      while IFS=$'\t' read -r bid ext mode; do
        [ -n "$ext" ] || continue
        # Already handled -> skip duti -s (it would prompt again)
        current="$(${pkgs.duti}/bin/duti -x "$ext" 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1 || true)"
        if [ "$mode" != ext ] && [ "''${current,,}" = "$bid" ]; then
          continue
        fi
        if [ "$mode" = ext ] || ! ${pkgs.duti}/bin/duti -s "$bid" ".$ext" all >/dev/null 2>&1; then
          printf '%s\t%s\n' "$bid" "$ext" >> "$FALLBACK"
        fi
      done < ${pkgs.writeText "file-extensions.tsv" extensionsTsv}

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
        --rawfile fallback "$FALLBACK" '
        ( $fallback | split("\n") | map(select(length > 0) | split("\t") | { bid: .[0], ext: .[1] }) ) as $desired
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
      rm -f "$TMP" "$TMP_NEW" "$FALLBACK"

      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -kill -r -domain local -domain system -domain user >/dev/null 2>&1 || true
    '';
  };
}
