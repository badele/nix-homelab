{
  self,
  lib,
  config,
  allocateIPForService,
  ...
}:
let

  hostIP = 1;
  cab1eAddress = "46.224.53.176";
  mainInterface = "trunk";

  mkAddress = vlan: ip: "192.168.${toString vlan}.${toString ip}";
  lanAddress = mkAddress config.homelab.vlans.lan.id hostIP;
  infraAddress = mkAddress config.homelab.vlans.infra.id hostIP;
  mgmtAddress = mkAddress config.homelab.vlans.mgmt.id hostIP;
  dmzAddress = mkAddress config.homelab.vlans.dmz.id hostIP;
  iotAddress = mkAddress config.homelab.vlans.iot.id hostIP;
  gwAddress = mkAddress config.homelab.vlans.lan.id 254;

in
{
  imports = [
    self.nixosModules.server

    # Default configuration for the clan machines.
    ./disko.nix
    ./networking.nix
    ../../modules/nixos/base.nix
  ];

  # Fix nixos build limits
  systemd.settings.Manager.DefaultLimitNOFILE = "8192:524288";

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

  ###############################################################################
  # Host information and features
  ###############################################################################
  homelab = {
    domain = "ma-cabane.net";
    domainEmailAdmin = "brunoadele+admin@gmail.com";
    stmpAccountUsername = "brunoadele@gmail.com";

    nameServer = infraAddress;
    host = {
      description = "Constellation private server";

      hostname = config.networking.hostName;
      interface = mainInterface;
      address = infraAddress;
      gateway = gwAddress;
      addresses = {
        lan = {
          interface = "br-lan";
          address = lanAddress;
          prefixLength = 24;
        };
        mgmt = {
          interface = "br-mgmt";
          address = mgmtAddress;
          prefixLength = 24;
        };
        infra = {
          interface = "br-infra";
          address = infraAddress;
          prefixLength = 24;
        };
        dmz = {
          interface = "br-dmz";
          address = dmzAddress;
          prefixLength = 24;
        };
        iot = {
          interface = "br-iot";
          address = iotAddress;
          prefixLength = 24;
        };
      };
      defaultAddressRef = "infra";
      managementAddressRef = "mgmt";

      nproc = 16;
    };

    features = {
      homelab-summary.enable = true;

      ##########################################################################
      # SSH tunneling
      ##########################################################################
      openssh.enable = true;
      openssh.openFirewall = true;
      openssh.registerScope = [ ];
      openssh.listenInterfaces = lib.mkForce [
        "br-mgmt"
      ];
      openssh.tunnels.netbird-cab1e-metrics = {
        enable = true;
        targetHost = "cab1e";
        targetAddress = cab1eAddress;
        targetUser = "metrics-tunnel";

        forwards = [
          {
            localPort = 11252;
            remotePort = 10252;
          }
          {
            localPort = 11253;
            remotePort = 10253;
          }
          {
            localPort = 11337;
            remotePort = 10337;
          }
        ];
      };

      # acme.enable = true;
      # acme.email = config.homelab.domainEmailAdmin;
      # acme.dnsProvider = "hetzner";
      # acme.tokenScope = "private";

      caddy.enable = true;
      caddy.tokenScope = "private";

      netbird = {
        enable = true;

        clients.infra = {
          enable = true;
          interface = "nb-infra";
          managementURL = "https://metro.ma-cabane.eu";
          portOffset = 0;
          listenInterfaces = [
            "br-lan"
          ];
          openFirewall = true;

          gateway = {
            enable = true;
            networks = [
              "192.168.244.0/24"
            ];
            routingFeatures = "server";
          };
        };
      };

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
      homepage-dashboard.dnsTargetAddress = allocateIPForService "infra" "homepage-dashboard";
      homepage-dashboard.listenInterfaces = lib.mkForce [
        "br-infra"
      ];
      homepage-dashboard.collectIntegrations = {
        cab1e = [ "netbird" ];
      };

      gatus.enable = true;
      gatus.openFirewall = true;
      gatus.registerScope = [ "private" ];
      gatus.serviceDomain = "signalisations.${config.homelab.domain}";
      gatus.dnsTargetAddress = allocateIPForService "infra" "gatus";
      gatus.listenInterfaces = lib.mkForce [
        "br-infra"
      ];
      gatus.collectIntegrations = {
        cab1e = [ "netbird" ];
      };

      goaccess.enable = true;
      goaccess.openFirewall = true;
      goaccess.serviceDomain = "portique.${config.homelab.domain}";
      goaccess.registerScope = [ "private" ];
      goaccess.dnsTargetAddress = allocateIPForService "infra" "goaccess";
      goaccess.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      grafana.enable = true;
      grafana.openFirewall = true;
      grafana.serviceDomain = "lampiotes.${config.homelab.domain}";
      grafana.registerScope = [ "private" ];
      grafana.dnsTargetAddress = allocateIPForService "infra" "grafana";
      grafana.listenInterfaces = lib.mkForce [
        "br-infra"
      ];
      grafana.collectIntegrations = {
        cab1e = [ "netbird" ];
      };

      it-tools.enable = true;
      it-tools.openFirewall = true;
      it-tools.registerScope = [ "private" ];
      it-tools.dnsTargetAddress = allocateIPForService "infra" "it-tools";
      it-tools.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      victoriametrics.enable = true;
      victoriametrics.openFirewall = true;
      victoriametrics.serviceDomain = "sondes.${config.homelab.domain}";
      victoriametrics.registerScope = [ "private" ];
      victoriametrics.dnsTargetAddress = allocateIPForService "infra" "victoriametrics";
      victoriametrics.listenInterfaces = lib.mkForce [
        "br-infra"
      ];
      victoriametrics.collectIntegrations = {
        cab1e = [ "netbird" ];
      };
      victoriametrics.integrationTargetOverrides.cab1e-netbird = {
        management = [ "127.0.0.1:11252" ];
        signal = [ "127.0.0.1:11253" ];
        relay = [ "127.0.0.1:11337" ];
      };

      victorialogs.enable = true;
      victorialogs.openFirewall = true;
      victorialogs.serviceDomain = "journaux.${config.homelab.domain}";
      victorialogs.registerScope = [ "private" ];
      victorialogs.dnsTargetAddress = allocateIPForService "infra" "victorialogs";
      victorialogs.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      vector.enable = true;
      vector.cef.enable = true;
      vector.cef.mikrotikFirewall.enable = true;
      vector.cef.mikrotikLogin.enable = true;
      vector.cef.mikrotikDhcp.enable = true;
      vector.cef.listenInterfaces = lib.mkForce [
        "br-infra"
      ];
      vector.victorialogs.enable = true;

      grist.enable = true;
      grist.openFirewall = true;
      grist.registerScope = [ "private" ];
      grist.dnsTargetAddress = allocateIPForService "infra" "grist";
      grist.listenInterfaces = lib.mkForce [
        "br-infra"
      ];

      mikrotik = {
        enable = true;
        backup = true;

        publishIntegrations = {
          homepage = true;
          gatus = true;
          grafana = true;
          vmalert = true;
          victoriametrics = {
            enable = true;
            listenInterfaces = [ "br-infra" ];
          };
        };

        prometheus = {
          enable = true;
          openFirewall = true;
          verbose = true;
          remoteDhcpServerVlan = "mgmt";
          serviceDomain = "mikrotik-exporter.infra.${config.homelab.domain}";
          registerScope = [ "private" ];
          dnsTargetAddress = allocateIPForService "infra" "mikrotik";
          listenInterfaces = lib.mkForce [
            "br-infra"
          ];
        };

        routers = [
          {
            name = "mkt254";
            host = "192.168.240.254";
          }
          {
            name = "mkt253";
            host = "192.168.240.253";
          }
          # {
          #   name = "mkt252";
          #   host = "192.168.244.252";
          # }
        ];
      };
    };
  };

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${mgmtAddress}";
}
