# ██╗   ██╗███████╗███████╗██████╗     ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗
# ██║   ██║██╔════╝██╔════╝██╔══██╗    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝
# ██║   ██║███████╗█████╗  ██████╔╝    ███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗
# ██║   ██║╚════██║██╔══╝  ██╔══██╗    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║
# ╚██████╔╝███████║███████╗██║  ██║    ███████║╚██████╗██║  ██║██║██║        ██║   ███████║
#  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝

{ pkgs, ... }:

let
  user-scripts = pkgs.stdenv.mkDerivation rec {
    pname = "user-scripts";
    version = "0.0.2";
    src = ./src;
    phases = "installPhase fixupPhase";
    installPhase = ''
      mkdir -p $out/bin
      cp ${src}/scripts/@* $out/bin/
      cp ${src}/scripts/status-* $out/bin/
      chmod +x $out/bin/*

      mkdir -p $out/share/zsh/site-functions
      cp ${src}/completions/* $out/share/zsh/site-functions/

      substituteInPlace $out/share/zsh/site-functions/_nixos-flake-options \
      --replace-fail "@jq@" "${pkgs.jq}/bin/jq" \
      --replace-fail "@nix@" "${pkgs.nix}/bin/nix"
    '';
  };
in
{
  home.packages = [
    user-scripts
  ];
}
