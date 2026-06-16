{ pkgs, ... }:
{
  home.packages = with pkgs; [
    typst
    tinymist
    kdePackages.okular
  ];
}
