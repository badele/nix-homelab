{ pkgs, ... }: {
  home.packages = with pkgs; [
    # LaTeX
    (texlive.combine {
      inherit (texlive) scheme-medium tabularray ninecolors msg lipsum pgf;
    })
    biber
    pplatex
    pstree
    texlab
    xdotool
    zathura
  ];
}
