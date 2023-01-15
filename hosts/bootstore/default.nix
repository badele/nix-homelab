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

  networking.interfaces.enp2s0.ipv4.routes = [{
    address = "192.168.254.0";
    prefixLength = 24;
    via = "192.168.0.10";
  }];

  system.stateVersion = "22.05";
}
