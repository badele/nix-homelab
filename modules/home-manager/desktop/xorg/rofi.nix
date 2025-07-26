{ config, lib, pkgs, ... }:
{
  programs.rofi =
    {
      enable = true;
      # theme = "solarized";
      extraConfig = {
        modi = "drun";
        font = "Source Code Pro 18";
        show-icon = true;
        icon-theme = "Papirus";
      };

    };
}
