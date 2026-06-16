{ pkgs, ... }:
{
  programs.go.enable = true;

  home.packages = with pkgs; [
    typst
    tinymist
    kdePackages.okular
  ];
}
