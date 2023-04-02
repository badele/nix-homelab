##########################################################
# HOME-MANAGER (user)
##########################################################
{ config
, inputs
, pkgs
, lib
, ...
}:
{
  imports = [
    #inputs.sops-nix.nixosModules.sops
    inputs.nix-colors.homeManagerModule
  ];

  home = {
    username = lib.mkDefault "root";
    homeDirectory = lib.mkDefault "/root/";
    stateVersion = lib.mkDefault "22.05";
  };

  colorscheme = inputs.nix-colors.colorSchemes.summerfruit-dark;

}
