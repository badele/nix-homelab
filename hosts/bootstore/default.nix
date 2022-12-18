{ pkgs
, lib
, ...
}: {
  imports = [
    ../../modules/hardware/hp-proliant-microserver-n40l.nix
    ../../modules/system/nix-serve.nix
    ../../modules/system/nfs/server.nix
  ];

  networking.hostName = "bootstore";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
