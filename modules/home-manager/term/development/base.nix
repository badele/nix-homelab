{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    git # Distributed version control system
    ghq # clone and manage remote repositories in a local directory
    jq # JSON pretty printer and manipulator
    just # justfile (Makefile like)
    lazygit # Terminal UI for git commands
  ];
}
