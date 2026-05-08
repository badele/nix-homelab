{ pkgs, ... }:
{

  home.packages = with pkgs; [
    ghostscript # Used for PDF processing (e.g., image conversion)

    # LaTeX
    (texliveMedium.withPackages (
      ps: with ps; [
        # ================================
        # Core CV dependencies
        # ================================

        enumitem # Used by CV (list formatting)
        fontawesome # Used by CV (icons)
        moresize # Used by CV (font size control)
        paracol # Used by CV (multi-column layout)
        pgf # Used by CV (tikz graphics)
        raleway # Used by CV (main font)
        transparent # Used by CV (transparency support)
        xifthen # Used by CV (conditional logic)
        xstring # Used by CV (string manipulation)

        geometry # Used by CV (page layout / margins)
        fancyhdr # Used by CV (header/footer control)
        graphics # Used by CV (images / graphicx)
        hyperref # Used by CV (links)
        tools # Used by CV (array / tabular extensions)

        # ================================
        # Used by Emacs (org export)
        # ================================

        wrapfig # Used by Org export (figures)
        capt-of # Used by Org export (captions)

        # ================================
        # Misc
        # ================================

        ifmtarg
        lipsum
        msg
        ninecolors
        tabularray
        scheme-medium
      ]
    ))

    # ================================
    # External tools
    # ================================

    biber # Used for bibliography (BibLaTeX)
    pplatex # Used for LaTeX preview/debug
    pstree # Not related to CV (process visualization)
    texlab # Used by editor (LSP for LaTeX)
    xdotool # Not related to CV (automation)
    zathura # Used to view generated PDF
  ];
}
