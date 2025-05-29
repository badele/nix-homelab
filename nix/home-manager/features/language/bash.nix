{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Bash
    nodePackages.bash-language-server
    shellcheck
    shfmt
    
    # Makefile
    checkmake
  ];
}
