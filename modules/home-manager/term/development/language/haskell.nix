{ pkgs, ... }:
{
  home.packages = with pkgs; [
    haskell-language-server
    haskellPackages.hoogle
    cabal-install
  ];
}
