{ config, lib, pkgs, ... }:
{

  imports = [
    ./dunst.nix
    ./rofi.nix
  ];

  home.packages = with pkgs;
    [
    ];
}
