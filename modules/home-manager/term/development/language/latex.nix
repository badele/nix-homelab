{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # LaTeX
    (texliveMedium.withPackages (
      ps: with ps; [
        enumitem
        fontawesome
        ifmtarg
        lipsum
        moresize
        msg
        ninecolors
        paracol
        pgf
        raleway
        tabularray
        transparent
        xifthen
      ]
    ))
    biber
    pplatex
    pstree
    texlab
    xdotool
    zathura
  ];
}
