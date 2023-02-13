{ lib
, ...
}:
{
  imports = [
    ../../modules/hardware/hp-proliant-microserver-n40l.nix
    ../../modules/system/homelab-cert.nix # cert for nginx server
    ../../roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../roles/prometheus/exporter/node.nix
    ../../roles/prometheus/exporter/snmp.nix
    ../../roles/prometheus/exporter/smokeping.nix
  ];

  networking = {
    useDHCP = false;
    hostName = "bootstore";

    defaultGateway = "192.168.0.1";
    nameservers = [
      "192.168.254.100"
      "192.168.254.101"
      "89.2.0.1"
      "89.2.0.2"
    ];

    interfaces.enp2s0.ipv4 = {
      addresses = [{
        address = "192.168.254.100";
        prefixLength = 24;
      }];

      routes = [{
        address = "192.168.254.0";
        prefixLength = 24;
        via = "192.168.0.10";
      }];
    };
  };

  system.stateVersion = "22.05";
}
