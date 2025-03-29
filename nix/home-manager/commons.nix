{ config, pkgs, lib, ... }: {

  imports = [
    ../../nix/home-manager/apps/bluetooth.nix
    ../../nix/home-manager/apps/development/internet.nix
    ../../nix/home-manager/apps/development/nix.nix
    ../../nix/home-manager/apps/graphics.nix
    ../../nix/home-manager/apps/system/file.nix
    ../../nix/home-manager/apps/system/performance.nix
    ../../nix/home-manager/apps/tools.nix
  ];
}
