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
    # Common tools and packages for all root user hosts
    ./commons.nix
  ];

  home = {
    username = lib.mkDefault "root";
    homeDirectory = lib.mkDefault "/root/";
    stateVersion = lib.mkDefault "22.05";
  };
}
