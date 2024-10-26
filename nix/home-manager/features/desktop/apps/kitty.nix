{ config, pkgs, inputs, ... }:

let
  hexPalette = with inputs.nix-rice.lib; palette.toRGBHex pkgs.rice.colorPalette;
in
{
  programs.kitty = {
    enable = true;
  };
}
