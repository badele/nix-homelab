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
  ];

  home = {
    username = lib.mkDefault "root";
    homeDirectory = lib.mkDefault "/root/";
    stateVersion = lib.mkDefault "24.05";
  };
}
