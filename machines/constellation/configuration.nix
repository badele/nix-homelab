{
  self,
  config,
  ...
}:
let
  targetIP = "192.168.254.154";
in
{
  imports = [
    self.nixosModules.server
    self.inputs.srvos.nixosModules.mixins-nginx

    # Default configuration for the clan machines.
    ./disko.nix
    ../../modules/shared.nix
    ../../modules/system/tailscale.nix
  ];

  # Host information
  homelab = {
    nameServer = targetIP;
    host = {
      hostname = "constellation";
      description = "Constellation private server";
      interface = "enp3s0";
      address = targetIP;
      gateway = "192.168.254.254";

      nproc = 16;
    };

    features = {
      homelab-summary.enable = true;

      blocky.enable = true;
      blocky.openFirewall = true;
      blocky.serviceDomain = "stop-pub.${config.homelab.domain}";

      step-ca.enable = true;
      step-ca.openFirewall = true;
      step-ca.serviceDomain = "ca.${config.homelab.domain}";

      lldap.enable = true;
      lldap.openFirewall = true;
      lldap.ldapDomain = "dc=ma-cabane,dc=lan";

      grafana.enable = true;
      grafana.openFirewall = true;
      grafana.serviceDomain = "lampiotes.${config.homelab.domain}";

      victoriametrics.enable = true;
      victoriametrics-agent.enable = true; # scrapping
      victoriametrics.openFirewall = true;
      victoriametrics.serviceDomain = "sondes.${config.homelab.domain}";
    };
  };

  # Static networking configuration
  networking = {
    useDHCP = false;
    interfaces."${config.homelab.host.interface}" = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = config.homelab.host.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = config.homelab.host.gateway;
      interface = config.homelab.host.interface;
    };

    nameservers = [
      config.homelab.nameServer
    ];
  };

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

  services.nginx.commonHttpConfig = ''
    log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
    access_log /var/log/nginx/private.log vcombined;
  '';

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${targetIP}";
}
