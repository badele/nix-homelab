{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go-grip
    markdownlint-cli
    pandoc
    proselint
  ];
}
