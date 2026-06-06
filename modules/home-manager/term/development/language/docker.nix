{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dockfmt # dockerfile formatter
  ];
}
