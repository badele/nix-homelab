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
    inputs.nix-colors.homeManagerModule

    # User
    ./base.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security

  ] ++ (builtins.attrValues outputs.homeManagerModules);

  # inv home.deploy ; neofetch ; ll
  colorscheme = inputs.nix-colors.colorSchemes.darktooth;
  wallpaper = pkgs.wallpapers.forest-deer-landscape;
}
