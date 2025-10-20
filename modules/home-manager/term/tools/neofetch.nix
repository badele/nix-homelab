{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    neofetch
  ];

  xdg.configFile."neofetch/config.conf".text = ''
    bold="off"
    ascii_bold="off"
    colors=(1 2 2 3 4 5)
    ascii_colors=(5 4)
  '';
}
