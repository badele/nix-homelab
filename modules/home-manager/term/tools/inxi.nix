{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: delete this file
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
