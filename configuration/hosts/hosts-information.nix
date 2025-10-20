{ config, ... }:
let
  nets = config.homelab.networks;
  hl = config.homelab;
in {
  imports = [
    ../../nix/modules/nixos/homelab
    ../hosts/badxps/host-information.nix
    ../hosts/hype10/host-information.nix
  ];

  homelab = {
    networkId = 10;
    networks = {
      infra = {
        vlanId = 10;
        net = "10.${toString hl.networkId}.${toString nets.infra.vlanId}.0";
        mask = 24;
      };
      adm = {
        vlanId = 20;
        net = "10.${toString hl.networkId}.${toString nets.adm.vlanId}.0";
        mask = 24;
      };
      dmz = {
        vlanId = 32;
        net = "192.168.${toString nets.dmz.vlanId}.0";
        mask = 24;
      };
      lan = {
        vlanId = 254;
        net = "192.168.${toString nets.lan.vlanId}.0";
        mask = 24;
      };
      box = {
        net = "192.168.0.0";
        mask = 24;
      };
      home = {
        net = "192.168.254.0";
        mask = 24;
      };
      vpn-cab1e = {
        net = "10.123.0.0";
        mask = 24;
      };
      vpn-server = {
        net = "10.123.45.0";
        mask = 24;
      };
      vpn-client = {
        net = "10.123.21.0";
        mask = 24;
      };
    };
  };
}

