{ lib
, ...
}:
let
  nodeexport_port = 9100;
in
{
  imports = [
    ../../modules/hardware/hp-proliant-microserver-n40l.nix
    ../../modules/system/homelab-cert.nix
    ../../modules/services # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../modules/services/prometheus/exporter/node.nix
    ../../modules/services/prometheus/exporter/mikrotik.nix
  ];

  networking.hostName = "bootstore";
  networking.useDHCP = lib.mkDefault true;

  networking.firewall.allowedTCPPorts = [
    nodeexport_port
  ];

  system.stateVersion = "22.05";
}
