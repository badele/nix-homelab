{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    xorg.xev
  ];
}
