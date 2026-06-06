{ pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/term/packages/nix.nix
    ../../modules/home-manager/term/tools/top
    ../../modules/home-manager/term/packages/sysadmin.nix
    ../../modules/home-manager/term/tools/user-scripts
  ];

}
