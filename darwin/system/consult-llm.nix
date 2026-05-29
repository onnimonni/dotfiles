{
  pkgs,
  inputs,
  username,
  ...
}:
let
  version = "3.0.6";
  consultLlm = pkgs.stdenvNoCC.mkDerivation {
    pname = "consult-llm";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/raine/consult-llm/releases/download/v${version}/consult-llm-darwin-arm64.tar.gz";
      hash = "sha256-UIEuiy8TilRgiEOYrE8rWaA0lXA2W0xEJhsBlx2bn4A=";
    };

    sourceRoot = ".";
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp consult-llm consult-llm-monitor $out/bin/
      chmod +x $out/bin/consult-llm $out/bin/consult-llm-monitor

      runHook postInstall
    '';
  };
  hm = inputs.home-manager.lib.hm;
in
{
  environment.systemPackages = [
    consultLlm
  ];

  home-manager.users.${username} = {
    home.activation.configureConsultLlmBackends = hm.dag.entryAfter [ "writeBoundary" ] ''
      ${consultLlm}/bin/consult-llm config set openai.backend codex-cli
    '';
  };
}
