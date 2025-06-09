# #########################################################
# HOME-MANAGER (user)
##########################################################
{ lib, ... }: {
  imports = [ ./commons.nix ];

  home = {
    username = lib.mkDefault "root";
    homeDirectory = lib.mkDefault "/root/";
    stateVersion = lib.mkDefault "22.05";
  };
}
