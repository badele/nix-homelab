# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    git # Distributed version control system
    jq # JSON pretty printer and manipulator
    just # justfile (Makefile like)
    lazygit # Terminal UI for git commands
    meld # Visual diff and merge tool
  ];
}
