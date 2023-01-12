{ lib
, ...
}: {
  imports = [
    ../../modules/hardware/rpi4-usb-boot.nix
    ../../modules/services # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../modules/services/prometheus/exporter/node.nix
    ../../modules/services/prometheus/exporter/snmp.nix
  ];

  networking.hostName = "rpi40";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
