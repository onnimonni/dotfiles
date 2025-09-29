{ pkgs, lib, ... }:
let
  ohsome-planet = pkgs.stdenv.mkDerivation rec {
    pname = "ohsome-planet";
    version = "1.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "GIScience";
      repo = "ohsome-planet";
      rev = "v${version}";
      sha256 = "sha256-166k6pk7s619q312g24jpa0n3wb5pmcy108q0jqdwjxha1if6nhc=";
    };

    nativeBuildInputs = with pkgs; [
      maven
      jdk
      makeWrapper
    ];

    buildPhase = ''
      mvn package -DskipTests
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp target/ohsome-planet-${version}.jar $out/lib/

      makeWrapper ${pkgs.jdk}/bin/java $out/bin/ohsome-planet \
        --add-flags "-jar $out/lib/ohsome-planet-${version}.jar"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Convert OpenStreetMaps pbf files into geoparquet";
      homepage = "https://github.com/GIScience/ohsome-planet";
      license = licenses.bsd3;
      platforms = platforms.all;
      mainProgram = "ohsome-planet";
    };
  };
in
{
  environment.systemPackages = [
    ohsome-planet
  ];
}