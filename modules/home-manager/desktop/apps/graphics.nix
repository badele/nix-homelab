# Graphics
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    geeqie # graphics file viewer
    gifsicle # create, edit, and inspect GIFs
    gimp # GNU Image Manipulation Program
    imagemagick # Image manipulation tools
    inkscape # Vector graphics editor
    krita # Digital painting application
    pastel # A command-line tool to generate, analyze, convert and manipulate colors
  ];
}
