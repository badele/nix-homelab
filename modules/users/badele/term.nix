{ pkgs, ... }:
{
  imports = [
    ../../home-manager/term/packages/nix.nix
    ../../home-manager/term/tools/top
    ../../home-manager/term/packages/sysadmin.nix
    ../../home-manager/term/tools/user-scripts
  ];

}
