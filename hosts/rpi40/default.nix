{ pkgs
, lib
, ...
}: {
  imports = [
    ../../modules/hardware/rpi4-usb-boot.nix
  ];

  networking.hostName = "rpi40";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
