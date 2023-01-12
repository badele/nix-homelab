{ lib
, ...
}:
{
  imports = [
    ../../modules/hardware/hp-proliant-microserver-n40l.nix
    ../../modules/system/homelab-cert.nix # For grafana, prometheus services
    ../../modules/services # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../modules/services/prometheus/exporter/node.nix
    ../../modules/services/prometheus/exporter/snmp.nix
  ];

  networking.hostName = "bootstore";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
