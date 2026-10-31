# oh-my-pi coding agent: prebuilt upstream release binary
# (upstream flake builds from source with no binary cache; brew tap breaks nix-darwin cleanup)
# https://github.com/can1357/oh-my-pi
{ pkgs, ... }:
let
  version = "18.13.3";
  omp = pkgs.stdenvNoCC.mkDerivation {
    pname = "omp";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-darwin-arm64";
      hash = "sha256-tEnQ0Nd5oLLmVfDOQdXEFKJT3nHGezr/wwplKPyWcxQ=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.installShellFiles ];
    installPhase = ''
      runHook preInstall
      install -Dm555 "$src" "$out"/bin/omp
      export HOME=$TMPDIR
      installShellCompletion --cmd omp \
        --bash <("$out"/bin/omp completions bash) \
        --zsh <("$out"/bin/omp completions zsh) \
        --fish <("$out"/bin/omp completions fish)
      runHook postInstall
    '';
    meta = {
      description = "Coding agent with the IDE wired in";
      homepage = "https://omp.sh";
      license = pkgs.lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "omp";
    };
  };
in
{
  environment.systemPackages = [ omp ];
}
