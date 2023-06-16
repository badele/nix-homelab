{ config, lib, pkgs, ... }:
let
  hexPalette = with pkgs.lib.nix-rice; palette.toRGBHex pkgs.rice.colorPalette;
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
        frame_color = hexPalette.bright.magenta;
        font = "${config.fontProfiles.regular.family} 12";
      };

      urgency_normal = {
        background = hexPalette.normal.black;
        foreground = hexPalette.bright.magenta;
        timeout = 10;
      };
    };
  };
}
