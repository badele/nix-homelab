{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnuplot # plotting
    graphviz # graph visualization
  ];
}
