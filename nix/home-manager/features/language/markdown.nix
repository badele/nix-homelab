{ pkgs, ... }:
{
  home.packages = with pkgs; [
    grip
    markdownlint-cli
    pandoc
    proselint
  ];
}
