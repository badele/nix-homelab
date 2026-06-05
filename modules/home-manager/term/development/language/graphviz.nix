{ pkgs, ... }:
{
  home.packages = with pkgs; [
    graphviz # graph visualization
  ];
}
