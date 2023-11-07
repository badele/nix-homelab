{ pkgs, ... }:
{
  programs.go.enable = true;

  home.packages = with pkgs; [
    go-symbols
    go-outline
    gocode-gomod
    godef
    gopls
    gotools
  ];
}
