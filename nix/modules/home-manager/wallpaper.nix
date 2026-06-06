{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.wallpaper = mkOption {
    type = types.str;
    default = "";
    description = ''
      Wallpaper path
    '';
  };
}
