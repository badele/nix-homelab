{
  config,
  lib,
  pkgs,
  ...
}:
let
  lanMac = "52:54:00:10:00:01";
  mgmtMac = "52:54:00:10:00:02";
  dmzMac = "52:54:00:10:00:03";
  infraMac = "52:54:00:10:00:04";
  iotMac = "52:54:00:10:00:05";
  bridgeHelper = "/run/wrappers/bin/qemu-bridge-helper";
in
{
  imports = [
    ../hangar16/configuration.nix
  ];

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  nixpkgs.system = lib.mkForce "x86_64-linux";

  boot.loader.grub.devices = [ "/dev/vda" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Provide iptables commands backed by nftables for software that still calls
  # iptables or ip6tables directly.
  environment.systemPackages = [
    pkgs.iptables-nftables-compat
  ];

  homelab.host = {
    hostname = lib.mkForce "hangar16-vm";
    description = lib.mkForce "Virtualized test variant of hangar16";
    interface = lib.mkForce "lan";
    address = lib.mkForce "192.168.254.116";
    gateway = lib.mkForce "192.168.254.254";
    addresses = lib.mkForce {
      lan = {
        interface = "lan";
        address = "192.168.254.116";
        prefixLength = 24;
      };
      mgmt = {
        interface = "mgmt";
        address = "192.168.240.116";
        prefixLength = 24;
      };
      infra = {
        interface = "infra";
        address = "192.168.244.116";
        prefixLength = 24;
      };
      dmz = {
        interface = "dmz";
        address = "192.168.32.116";
        prefixLength = 24;
      };
      iot = {
        interface = "iot";
        address = "192.168.40.116";
        prefixLength = 24;
      };
    };
    defaultAddressRef = lib.mkForce "lan";
    managementAddressRef = lib.mkForce "mgmt";
  };

  homelab.features = {
    blocky.serviceDomain = lib.mkForce "blocky-vm.${config.homelab.domain}";
    # hangar16 already sets blocky.listenInterfaces with mkForce, which is
    # equivalent to mkOverride 50. We use mkOverride 49 here so the VM replaces
    # the inherited list instead of merging with it.
    blocky.listenInterfaces = lib.mkOverride 49 [
      "dmz"
    ];
    blocky.dnsTargetAddress = lib.mkForce config.homelab.host.address;

    homepage-dashboard.serviceDomain = lib.mkForce "labrique-vm.${config.homelab.domain}";
    homepage-dashboard.listenInterfaces = lib.mkOverride 40 [ "infra" ];
    gatus.serviceDomain = lib.mkForce "signalisations-vm.${config.homelab.domain}";
    gatus.listenInterfaces = lib.mkOverride 40 [ "infra" ];
    grafana.serviceDomain = lib.mkForce "lampiotes-vm.${config.homelab.domain}";
    grafana.listenInterfaces = lib.mkOverride 40 [ "infra" ];
    victoriametrics.serviceDomain = lib.mkForce "sondes-vm.${config.homelab.domain}";
    victoriametrics.listenInterfaces = lib.mkOverride 40 [ "infra" ];
  };

  # Rename network devices
  systemd.network.links = lib.mkForce {
    "10-lan" = {
      matchConfig.MACAddress = lanMac;
      linkConfig.Name = "lan";
    };

    "10-mgmt" = {
      matchConfig.MACAddress = mgmtMac;
      linkConfig.Name = "mgmt";
    };

    "10-dmz" = {
      matchConfig.MACAddress = dmzMac;
      linkConfig.Name = "dmz";
    };

    "10-infra" = {
      matchConfig.MACAddress = infraMac;
      linkConfig.Name = "infra";
    };

    "10-iot" = {
      matchConfig.MACAddress = iotMac;
      linkConfig.Name = "iot";
    };
  };

  # Configure static network address
  networking = {
    hostName = "hangar16-vm";
    nftables.enable = true;

    networkmanager.unmanaged = lib.mkForce [
      "interface-name:lan"
      "interface-name:mgmt"
      "interface-name:dmz"
      "interface-name:infra"
      "interface-name:iot"
    ];
    defaultGateway = lib.mkForce {
      address = "192.168.254.254";
      interface = "lan";
    };

    nameservers = lib.mkForce [ "192.168.254.154" ];
    vlans = lib.mkForce { };
    bridges = lib.mkForce { };
    interfaces = lib.mkForce {
      lan.ipv4.addresses = [
        {
          address = "192.168.254.116";
          prefixLength = 24;
        }
      ];

      mgmt.ipv4.addresses = [
        {
          address = "192.168.240.116";
          prefixLength = 24;
        }
      ];

      dmz.ipv4.addresses = [
        {
          address = "192.168.32.116";
          prefixLength = 24;
        }
      ];

      infra.ipv4.addresses = [
        {
          address = "192.168.244.116";
          prefixLength = 24;
        }
      ];

      iot.ipv4.addresses = [
        {
          address = "192.168.40.116";
          prefixLength = 24;
        }
      ];
    };
  };

  # Use blocky local DNS server for resolving local homelab services and domains.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      # DNS = [ config.homelab.nameServer ];
      DNS = [ "192.168.32.116" ];
      Domains = [ config.homelab.domain ];
      LLMNR = "no";
    };
  };

  # Enable QEMU virtualisation instance
  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 8192;
      qemu.networkingOptions = lib.mkForce [
        "-device virtio-net-pci,netdev=lan,mac=${lanMac}"
        "-netdev bridge,id=lan,br=br-lan,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=mgmt,mac=${mgmtMac}"
        "-netdev bridge,id=mgmt,br=br-mgmt,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=dmz,mac=${dmzMac}"
        "-netdev bridge,id=dmz,br=br-dmz,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=infra,mac=${infraMac}"
        "-netdev bridge,id=infra,br=br-infra,helper=${bridgeHelper}"

        "-device virtio-net-pci,netdev=iot,mac=${iotMac}"
        "-netdev bridge,id=iot,br=br-iot,helper=${bridgeHelper}"
      ];
    };
  };
}
