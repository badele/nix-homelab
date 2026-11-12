{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.rofi = {
    enable = true;
    # theme = "solarized";
    settings = {
      modi = "drun";
      font = "Source Code Pro 18";
      "show-icons" = true;
      "icon-theme" = "Papirus";
    };

  };
}
