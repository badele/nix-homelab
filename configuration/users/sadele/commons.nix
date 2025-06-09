{ config
, inputs
, outputs
, pkgs
, lib
, ...
}:
let
  mkTuple = lib.hm.gvariant.mkTuple;
in
{

  ##############################################################################
  # Common user conf
  ##############################################################################
  home = {
    username = lib.mkDefault "sadele";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "22.11";
  };

  programs = { };

  ##############################################################################
  # Packages
  ##############################################################################
  home.packages = with pkgs; [
    firefox
    gimp
    inkscape
    libreoffice
  ];

  ##############################################################################
  # Gnome configuration
  ##############################################################################
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      "current" = "uint32 0";
      "sources" = [ (mkTuple [ "xkb" "fr" ]) ];
    };
  };
}
