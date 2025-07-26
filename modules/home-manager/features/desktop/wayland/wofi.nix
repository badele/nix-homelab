{ config, lib, pkgs, ... }:
let
  pass-wofi = pkgs.pass-wofi.override {
    pass = config.programs.password-store.package;
  };
in
{
  home.packages = with pkgs; [
    wofi
    pass-wofi
  ];
}
