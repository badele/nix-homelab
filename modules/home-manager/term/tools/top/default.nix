{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    procps
  ];

  xdg.configFile."procps/toprc".text = (builtins.readFile ./toprc);
}
