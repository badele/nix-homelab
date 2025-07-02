{ inputs, config, pkgs, lib, ... }:
let
  cfg = config.homelab.hosts.hype10;
  hostconfiguration = {
    description = "Hypervisor Hype10";
    dnsalias = [ ];
    roles = [ "coredns" "virtualization" ];

    icon =
      "https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png";
    os = "NixOS";
    nproc = 8;

    parent = "router-ladbedroom";
    zone = "ladbedroom";

    hostIpId = 10;
    ipv4 = cfg.params.net.vlans.lan.address;

    params = {
      net = {
        interface = "enp1s0";
        vlans = {
          lan = {
            interface = "enp1s0";
            id = 254;
            address = "192.168.${toString cfg.params.net.vlans.lan.id}.${
                toString cfg.hostIpId
              }";
          };
          infra = {
            id = 10;
            address = "10.10.${toString cfg.params.net.vlans.infra.id}.${
                toString cfg.hostIpId
              }";
          };
          adm = {
            id = 20;
            address = "10.10.${toString cfg.params.net.vlans.adm.id}.${
                toString cfg.hostIpId
              }";
          };
          dmz = {
            id = 32;
            address = "192.168.${toString cfg.params.net.vlans.dmz.id}.${
                toString cfg.hostIpId
              }";
          };
        };
      };
    };
  };
in {
  imports = [ ];

  homelab.hosts.hype10 = hostconfiguration;
}
