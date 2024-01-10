{ config, lib, pkgs, inputs, ... }:
let
  hexPalette = with inputs.nix-rice.lib; palette.toRGBHex pkgs.rice.colorPalette;
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
        font = "${config.fontProfiles.monospace.family} 12";
      };

      urgency_normal = {
        background = hexPalette.normal.black;
        foreground = hexPalette.bright.magenta;
        timeout = 10;
      };
    };
  };
}
