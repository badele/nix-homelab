{
  self,
  config,
  ...
}:
let
  targetIP = "91.99.130.127";
in
{
  imports = [
    # Install server profile
    # see ./modules/flake-module.nix
    self.nixosModules.server
    self.nixosModules.hardware-hetzner-cloud
    self.inputs.srvos.nixosModules.mixins-nginx

    # Default shared configuration for the clan machines.
    ../../modules/shared.nix

    ../../modules/server.nix
    ../../modules/system/borgbackup.nix
    ../../modules/system/reaction.nix
    ../../modules/system/tailscale.nix

    # houston infra
    ./disko.nix

    # houston apps
    ./modules/authelia.nix
    ./modules/dokuwiki.nix
    # ./modules/goaccess.nix
    ./modules/grafana.nix
    # ./modules/homepage-dashboard.nix
    ./modules/influxdb.nix
    ./modules/it-tools.nix
    ./modules/linkding.nix
    ./modules/lldap.nix
    ./modules/miniflux.nix
    # ./modules/pawtunes.nix
    ./modules/reaction.nix
    ./modules/shaarli.nix
    ./modules/telegraf
    ./modules/vector
    ./modules/victoriametrics.nix
    # ./modules/wastebin.nix
  ];

  # For user namespace remapping for docker/podman rootfull containers
  users = {
    users.root = {
      subUidRanges = [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
    };
  };

  # Host information
  homelab = {
    domain = "ma-cabane.eu";
    # nameServer = "";
    host = {
      hostname = config.networking.hostName;
      description = "Houston main public server";
      interface = "enp1s0";
      address = targetIP;
      # gateway = "192.168.254.254";

      nproc = 4;
    };

    features = {
      homelab-summary.enable = true;

      homepage-dashboard.enable = true;
      homepage-dashboard.openFirewall = true;
      homepage-dashboard.serviceDomain = "labrique.${config.homelab.domain}";

      gatus.enable = true;
      gatus.openFirewall = true;
      gatus.serviceDomain = "signalisations.${config.homelab.domain}";

      goaccess.enable = true;
      goaccess.openFirewall = true;
      goaccess.serviceDomain = "portique.${config.homelab.domain}";

      pawtunes.enable = true;
      pawtunes.openFirewall = true;
      pawtunes.serviceDomain = "radio.${config.homelab.domain}";

      wastebin.enable = true;
      wastebin.openFirewall = true;
      wastebin.serviceDomain = "carte-perforee.${config.homelab.domain}";
    };
  };

  # This is your user login name.
  # users.users.user.name = "badele";

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${targetIP}";

  # # Zerotier needs one controller to accept new nodes. Once accepted
  # # the controller can be offline and routing still works.
  # clan.core.networking.zerotier.controller.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
