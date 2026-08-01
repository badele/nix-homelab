{
  self,
  lib,
  config,
  ...
}:
let
  privateSuffixIPv4 = "1";
  targetIP = "192.168.254.${privateSuffixIPv4}";
  mainInterface = "lan";
in
{
  imports = [
    self.nixosModules.server

    # Default configuration for the clan machines.
    ./disko.nix
    ../../modules/nixos/base.nix
  ];

  # Fix nixos build limits
  systemd.settings.Manager.DefaultLimitNOFILE = "8192:524288";

  # Host information
  homelab = {
    domain = "ma-cabane.net";
    domainEmailAdmin = "brunoadele+admin@gmail.com";
    stmpAccountUsername = "brunoadele@gmail.com";

    nameServer = targetIP;
    host = {
      hostname = config.homelab.host.hostname;
      description = "Constellation private server";
      interface = mainInterface;
      address = targetIP;
      gateway = "192.168.254.254";

      nproc = 16;
    };

    features = {
      homelab-summary.enable = true;

      tailscale.enable = true;

      openssh.enable = true;
      openssh.openFirewall = true;
      openssh.registerScope = [ ];
      openssh.listenInterfaces = lib.mkForce [
        "br-mgmt"
      ];

      # acme.enable = true;
      # acme.email = config.homelab.domainEmailAdmin;
      # acme.dnsProvider = "hetzner";
      # acme.tokenScope = "private";

      caddy.enable = true;
      caddy.tokenScope = "private";

      ##########################################################################
      # Private homelab DNS server
      ##########################################################################
      blocky.enable = true;
      blocky.openFirewall = true;
      blocky.enableMetrics = true;
      blocky.listenInterfaces = lib.mkForce [
        "br-dmz"
        "br-infra"
        "br-iot"
        "br-lan"
        "br-mgmt"
      ];

      blocky.dnsTargetAddress = lib.mkForce config.homelab.host.address; # blocky DNS server address
      blocky.serviceDomain = "stop-pub.${config.homelab.domain}";
      blocky.registerScope = [ "private" ]; # Register this service in the private DNS zone of the homelab
      blocky.dnsRegistrationScopes = [ "private" ]; # Add all private service on this blocky instance service

      homepage-dashboard.enable = true;
      homepage-dashboard.openFirewall = true;
      homepage-dashboard.serviceDomain = "labrique.${config.homelab.domain}";
      homepage-dashboard.registerScope = [ "private" ];
      homepage-dashboard.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      gatus.enable = true;
      gatus.openFirewall = true;
      gatus.registerScope = [ "private" ];
      gatus.serviceDomain = "signalisations.${config.homelab.domain}";
      gatus.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      goaccess.enable = true;
      goaccess.openFirewall = true;
      goaccess.serviceDomain = "portique.${config.homelab.domain}";
      goaccess.registerScope = [ "private" ];
      goaccess.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      grafana.enable = true;
      grafana.openFirewall = true;
      grafana.serviceDomain = "lampiotes.${config.homelab.domain}";
      grafana.registerScope = [ "private" ];
      grafana.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      it-tools.enable = true;
      it-tools.openFirewall = true;
      it-tools.registerScope = [ "private" ];
      it-tools.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      victoriametrics.enable = true;
      victoriametrics.openFirewall = true;
      victoriametrics.serviceDomain = "sondes.${config.homelab.domain}";
      victoriametrics.registerScope = [ "private" ];
      victoriametrics.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      grist.enable = true;
      grist.openFirewall = true;
      grist.registerScope = [ "private" ];
      grist.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      mikrotik = {
        enable = true;
        backup = true;
        routers = [
          {
            name = "mkt254";
            host = "192.168.240.254";
          }
          {
            name = "mkt253";
            host = "192.168.240.253";
          }
        ];
      };
    };
  };

  # Static networking configuration
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSStubListener = "no";
      MulticastDNS = "no";
    };
  };

  # Rename the main network interface to the configured name for consistency across machines.
  systemd.network.links."10-lan" = {
    matchConfig = {
      Path = "pci-0000:03:00.0";
      Driver = "igc";
    };

    linkConfig = {
      Name = config.homelab.host.interface;
    };
  };

  networking = {
    enableIPv6 = false;

    useDHCP = false;

    vlans = {
      "vlan-${config.homelab.vlans.mgmt.name}" = {
        id = config.homelab.vlans.mgmt.id;
        interface = config.homelab.host.interface;
      };

      "vlan-${config.homelab.vlans.dmz.name}" = {
        id = config.homelab.vlans.dmz.id;
        interface = config.homelab.host.interface;
      };

      "vlan-${config.homelab.vlans.infra.name}" = {
        id = config.homelab.vlans.infra.id;
        interface = config.homelab.host.interface;
      };

      "vlan-${config.homelab.vlans.iot.name}" = {
        id = config.homelab.vlans.iot.id;
        interface = config.homelab.host.interface;
      };
    };

    bridges = {
      br-lan.interfaces = [ config.homelab.vlans.lan.name ];
      br-mgmt.interfaces = [ "vlan-${config.homelab.vlans.mgmt.name}" ];
      br-dmz.interfaces = [ "vlan-${config.homelab.vlans.dmz.name}" ];
      br-infra.interfaces = [ "vlan-${config.homelab.vlans.infra.name}" ];
      br-iot.interfaces = [ "vlan-${config.homelab.vlans.iot.name}" ];
    };

    interfaces = {
      "${config.homelab.vlans.lan.name}" = { };
      "vlan-${config.homelab.vlans.mgmt.name}" = { };
      "vlan-${config.homelab.vlans.dmz.name}" = { };
      "vlan-${config.homelab.vlans.infra.name}" = { };
      "vlan-${config.homelab.vlans.iot.name}" = { };

      br-lan.ipv4.addresses = [
        {
          address = config.homelab.host.address;
          prefixLength = 24;
        }
      ];

      br-mgmt.ipv4.addresses = [
        {
          address = "192.168.240.${privateSuffixIPv4}";
          prefixLength = 24;
        }
      ];

      br-dmz.ipv4.addresses = [
        {
          address = "192.168.32.${privateSuffixIPv4}";
          prefixLength = 24;
        }
      ];

      br-infra.ipv4.addresses = [
        {
          address = "192.168.244.${privateSuffixIPv4}";
          prefixLength = 24;
        }
      ];

      br-iot.ipv4.addresses = [
        {
          address = "192.168.40.${privateSuffixIPv4}";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = config.homelab.host.gateway;
      interface = "br-lan";
    };

    nameservers = [
      config.homelab.nameServer
    ];
  };

  security.sudo.execWheelOnly = lib.mkForce false;

  # For user namespace remapping for docker/podman rootfull containers
  users = {
    users.root = {
      subUidRanges = [
        {
          startUid = 1000000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 1000000;
          count = 65536;
        }
      ];
    };
  };

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${targetIP}";
}
