{
  config,
  allocateIPv4AddressesForServices,
  ...
}:
{
  # Static networking configuration
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSStubListener = "no";
      MulticastDNS = "no";
    };
  };

  # Rename the main network interface to the configured name for consistency across machines.
  systemd.network.links."10-trunk" = {
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
      br-lan.interfaces = [ config.homelab.host.interface ];
      br-mgmt.interfaces = [ "vlan-${config.homelab.vlans.mgmt.name}" ];
      br-dmz.interfaces = [ "vlan-${config.homelab.vlans.dmz.name}" ];
      br-infra.interfaces = [ "vlan-${config.homelab.vlans.infra.name}" ];
      br-iot.interfaces = [ "vlan-${config.homelab.vlans.iot.name}" ];
    };

    interfaces = {
      "${config.homelab.host.interface}" = { };
      "${config.homelab.vlans.lan.name}" = { };
      "vlan-${config.homelab.vlans.mgmt.name}" = { };
      "vlan-${config.homelab.vlans.dmz.name}" = { };
      "vlan-${config.homelab.vlans.infra.name}" = { };
      "vlan-${config.homelab.vlans.iot.name}" = { };

      br-lan.ipv4.addresses = [
        {
          address = config.homelab.host.addresses.lan.address;
          prefixLength = 24;
        }
      ];

      br-mgmt.ipv4.addresses = [
        {
          address = config.homelab.host.addresses.mgmt.address;
          prefixLength = 24;
        }
      ];

      br-dmz.ipv4.addresses = [
        {
          address = config.homelab.host.addresses.dmz.address;
          prefixLength = 24;
        }
      ];

      br-infra.ipv4.addresses = [
        {
          address = config.homelab.host.addresses.infra.address;
          prefixLength = 24;
        }
      ]
      ++ allocateIPv4AddressesForServices "infra" [
        "homepage-dashboard"
        "gatus"
        "goaccess"
        "grafana"
        "it-tools"
        "victoriametrics"
        "victorialogs"
        "grist"
        "mikrotik"
      ];

      br-iot.ipv4.addresses = [
        {
          address = config.homelab.host.addresses.iot.address;
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

}
