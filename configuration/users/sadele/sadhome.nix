##########################################################
# HOME-MANAGER (user)
##########################################################
{ config
, inputs
, outputs
, pkgs
, lib
, ...
}:
let
  feh = "${pkgs.feh}/bin/feh";
in
{
  imports = [
    # User
    ./commons.nix

    # Commons packages
    ../../nix/home-manager/commons/packages.nix

    # Term
    ../../nix/home-manager/features/term/base.nix

    # Desktop
    ../../nix/home-manager/features/desktop/commons/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs; [ ];
  programs = { };

  # inv home.deploy ; neofetch ; ll
  wallpaper = pkgs.wallpapers.forest-deer-landscape;
}
