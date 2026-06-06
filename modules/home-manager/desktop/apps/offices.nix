# Graphics
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libreoffice # Office suite
    inkscape # PDF manipulation
  ];
}
