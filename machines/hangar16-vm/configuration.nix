{
  config,
  lib,
  ...
}:
let
  lanMac = "52:54:00:10:00:01";
  admMac = "52:54:00:10:00:02";
  dmzMac = "52:54:00:10:00:03";
  iotMac = "52:54:00:10:00:04";
  bridgeHelper = "/run/wrappers/bin/qemu-bridge-helper";
in
{
  imports = [
    ../hangar16/configuration.nix
  ];

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  nixpkgs.system = lib.mkForce "x86_64-linux";

  networking.hostName = "hangar16-vm";

  homelab.host = {
    hostname = lib.mkForce "hangar16-vm";
    description = lib.mkForce "Virtualized test variant of hangar16";
    interface = lib.mkForce "lan0";
    address = lib.mkForce "192.168.254.116";
    gateway = lib.mkForce "192.168.254.254";
  };

  homelab.features = {
    blocky.serviceDomain = lib.mkForce "blocky-vm.${config.homelab.domain}";
    blocky.listenInterfaces = lib.mkForce [
      "lan0"
      "adm0"
      "dmz0"
      "iot0"
    ];
    blocky.dnsTargetAddress = lib.mkForce config.homelab.host.address;

    homepage-dashboard.serviceDomain = lib.mkForce "labrique-vm.${config.homelab.domain}";
    gatus.serviceDomain = lib.mkForce "signalisations-vm.${config.homelab.domain}";
    grafana.serviceDomain = lib.mkForce "lampiotes-vm.${config.homelab.domain}";
    victoriametrics.serviceDomain = lib.mkForce "sondes-vm.${config.homelab.domain}";
  };

  systemd.network.links = lib.mkForce {
    "10-lan0" = {
      matchConfig.MACAddress = lanMac;
      linkConfig.Name = "lan0";
    };

    "10-adm0" = {
      matchConfig.MACAddress = admMac;
      linkConfig.Name = "adm0";
    };

    "10-dmz0" = {
      matchConfig.MACAddress = dmzMac;
      linkConfig.Name = "dmz0";
    };

    "10-iot0" = {
      matchConfig.MACAddress = iotMac;
      linkConfig.Name = "iot0";
    };
  };

  networking = {
    networkmanager.unmanaged = lib.mkForce [
      "interface-name:lan0"
      "interface-name:adm0"
      "interface-name:dmz0"
      "interface-name:iot0"
    ];
    defaultGateway = lib.mkForce {
      address = "192.168.254.254";
      interface = "lan0";
    };
    nameservers = lib.mkForce [ "192.168.254.154" ];
    vlans = lib.mkForce { };
    bridges = lib.mkForce { };
    interfaces = lib.mkForce {
      lan0.ipv4.addresses = [
        {
          address = "192.168.254.116";
          prefixLength = 24;
        }
      ];

      adm0.ipv4.addresses = [
        {
          address = "192.168.240.116";
          prefixLength = 24;
        }
      ];

      dmz0.ipv4.addresses = [
        {
          address = "192.168.32.116";
          prefixLength = 24;
        }
      ];

      iot0.ipv4.addresses = [
        {
          address = "192.168.40.116";
          prefixLength = 24;
        }
      ];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [ config.homelab.nameServer ];
      Domains = [ config.homelab.domain ];
      LLMNR = "no";
    };
  };

  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 8192;
      qemu.networkingOptions = lib.mkForce [
        "-device virtio-net-pci,netdev=lan0,mac=${lanMac}"
        "-netdev bridge,id=lan0,br=br-lan,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=adm0,mac=${admMac}"
        "-netdev bridge,id=adm0,br=br-adm,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=dmz0,mac=${dmzMac}"
        "-netdev bridge,id=dmz0,br=br-dmz,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=iot0,mac=${iotMac}"
        "-netdev bridge,id=iot0,br=br-iot,helper=${bridgeHelper}"
      ];
    };
  };
}
