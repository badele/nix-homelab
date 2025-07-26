{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
  ];
}
