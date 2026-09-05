{
  self,
  config,
  ...
}:
let
  targetIP = "46.224.53.176";
in
{
  imports = [
    # Install server profile.
    self.nixosModules.server
    self.nixosModules.hardware-hetzner-cloud

    # Default shared configuration for the clan machines.
    ../../modules/nixos/base.nix

    ../../modules/nixos/server.nix

    # cab1e infra.
    ./disko.nix
  ];

  homelab = {
    domain = "ma-cabane.eu";
    domainEmailAdmin = "brunoadele+admin@gmail.com";
    stmpAccountUsername = "brunoadele@gmail.com";

    host = {
      hostname = config.networking.hostName;
      description = "cab1e VPN server";
      interface = "enp1s0";
      address = targetIP;
      addresses.public = {
        interface = "enp1s0";
        address = targetIP;
      };
      defaultAddressRef = "public";
      managementAddressRef = "public";
      publicAddressRef = "public";
      nproc = 1;
    };

    features = {
      homelab-summary.enable = true;

      acme.enable = true;
      acme.email = config.homelab.domainEmailAdmin;
      acme.dnsProvider = "hetzner";
      acme.tokenScope = "public";

      caddy.enable = true;
      caddy.tokenScope = "public";

      openssh = {
        enable = true;
        openFirewall = true;
        listenInterfaces = [ config.homelab.host.interface ];

        tunnelUsers.metrics-tunnel = {
          enable = true;
          authorizedKeyGenerators = [
            "openssh-tunnel-constellation-netbird-cab1e-metrics"
          ];
          permitOpen = [
            "127.0.0.1:10252"
            "127.0.0.1:10253"
            "127.0.0.1:10337"
          ];
        };
      };

      netbird = {
        enable = true;

        publishIntegrations = {
          homepage = true;
          gatus = true;
          grafana = true;
          victoriametrics = {
            enable = true;
            listenInterfaces = [ "lo" ];
          };
        };

        public = {
          enable = true;
          serviceDomain = "metro.${config.homelab.domain}";
          listenInterfaces = [ config.homelab.host.interface ];
          registerScope = [ "public" ];
          dnsTargetAddress = config.homelab.host.address;
          openFirewall = true;
        };

        auth = {
          provider = "zitadel";
          issuerURL = "https://douane.ma-cabane.eu";
          clientId = "388594052196532225";
        };
      };
    };
  };

  services.resolved.settings = {
    Resolve = {
      MulticastDNS = "no";
    };
  };

  # Set this for clan commands use ssh i.e. `clan machines update`.
  clan.core.networking.targetHost = "root@${targetIP}";

  nixpkgs.hostPlatform = "x86_64-linux";
}
