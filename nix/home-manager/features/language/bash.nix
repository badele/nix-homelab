{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Bash
    bash-language-server
    shellcheck
    shfmt

    # Makefile
    checkmake
  ];
}
