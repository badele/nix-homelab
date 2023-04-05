{ config, lib, pkgs, ... }:
let
  inherit (config) colorscheme;
  inherit (colorscheme) colors;
in
{

  home.packages = with pkgs; [
    libnotify
  ];

  services.dunst = {
    enable = true;

    settings = {
      global = {
        width = 300;
        height = 300;
        offset = "30x50";
        origin = "top-right";
        transparency = 10;
        frame_color = "#${colors.base0C}";
        font = "${config.fontProfiles.regular.family} 12";
      };

      urgency_normal = {
        background = "#${colors.base00}";
        foreground = "#eceff1";
        timeout = 10;
      };
    };
  };
}
