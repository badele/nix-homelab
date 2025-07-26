{ config, lib, pkgs, ... }:
let
  myinxi = pkgs.inxi.override {
    withRecommendedSystemPrograms = true;
  };
in
{
  home.packages = with pkgs; [
    myinxi
  ];
}
