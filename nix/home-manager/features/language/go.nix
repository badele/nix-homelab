{ pkgs, ... }:
{
  programs.go.enable = true;

  home.packages = with pkgs; [
    go-outline
    gocode-gomod
    godef
    gopls
    gotools
  ];
}
