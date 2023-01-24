{ lib
, ...
}: {
  imports = [
    ../../modules/hardware/rpi4-usb-boot.nix
    ../../roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../roles/prometheus/exporter/node.nix
  ];

  networking.hostName = "rpi40";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
