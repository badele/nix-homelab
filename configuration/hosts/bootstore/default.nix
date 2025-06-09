{ lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/modules/nixos/homelab
    ../../nix/nixos/features/commons

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../nix/nixos/roles/prometheus/exporter/node.nix
    ../../nix/nixos/roles/prometheus/exporter/snmp.nix
    ../../nix/nixos/roles/prometheus/exporter/smokeping.nix
  ];

  networking = {
    useDHCP = false;
    hostName = "bootstore";

    defaultGateway = "192.168.254.254";
    nameservers = [
      "192.168.254.101" # use CoreDNS server
      "89.2.0.1"
      "89.2.0.2"
    ];

    interfaces.enp2s0.ipv4 = {
      addresses = [{
        address = "192.168.254.100";
        prefixLength = 24;
      }];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "22.11";
}
