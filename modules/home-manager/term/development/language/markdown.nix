{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Markdown
    marksman
    markdownlint-cli
  ];
}
