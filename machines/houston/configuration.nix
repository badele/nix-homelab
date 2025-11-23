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
    ./modules/influxdb.nix
    ./modules/reaction.nix
    ./modules/telegraf
    ./modules/vector
    ./modules/victoriametrics.nix
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

  # Fix nixos build limits
  systemd.settings.Manager.DefaultLimitNOFILE = "8192:524288";

  # Host information
  homelab = {
    domain = "ma-cabane.eu";
    domainEmailAdmin = "brunoadele+admin@gmail.com";
    stmpAccountUsername = "brunoadele@gmail.com";

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

      acme.enable = true;
      acme.email = config.homelab.domainEmailAdmin;
      acme.dnsProvider = "hetzner";

      authentik.enable = true;
      authentik.openFirewall = true;
      authentik.serviceDomain = "douane.${config.homelab.domain}";

      homepage-dashboard.enable = true;
      homepage-dashboard.openFirewall = true;
      homepage-dashboard.serviceDomain = "labrique.${config.homelab.domain}";

      gatus.enable = true;
      gatus.openFirewall = true;
      gatus.serviceDomain = "signalisations.${config.homelab.domain}";

      goaccess.enable = true;
      goaccess.openFirewall = true;
      goaccess.serviceDomain = "portique.${config.homelab.domain}";

      wastebin.enable = true;
      wastebin.openFirewall = true;
      wastebin.serviceDomain = "carte-perforee.${config.homelab.domain}";

      it-tools.enable = true;
      it-tools.openFirewall = true;
      it-tools.serviceDomain = "boite-a-outils.${config.homelab.domain}";

      linkding.enable = true;
      linkding.openFirewall = true;
      linkding.serviceDomain = "bonnes-adresses.${config.homelab.domain}";

      miniflux.enable = true;
      miniflux.openFirewall = true;
      miniflux.serviceDomain = "journaliste.${config.homelab.domain}";

      radio.enable = true;
      radio.openFirewall = true;
      radio.stations = [
        {
          name = "Dance Wave! // Dance";
          url = "https://dancewave.online/dance.mp3";
        }
        {
          name = "Hirschmilch // Chillout";
          url = "http://hirschmilch.de:7000/chillout.mp3";
        }
        {
          name = "1 FM Reggae // Reggae";
          url = "http://strm112.1.fm/reggae_mobile_mp3";
        }
        {
          name = "SUNSET JAZZ RADIO // Jazz";
          url = "https://radio2.vip-radios.fm:18077/stream-mp3-SunsetJazz";
        }
        {
          name = "Hirschmilch Organic House // Electro";
          url = "https://hirschmilch.de:7000/organic-house.aac";
        }
        {
          name = "Hirschmilch Electronic // Electro";
          url = "https://hirschmilch.de:7000/electronic.aac";
        }
        {
          name = "Hirschmilch Prog-House // Electro";
          url = "http://hirschmilch.de:7000/prog-house.aac";
        }
        {
          name = "Hirschmilch Progressive // Electro";
          url = "http://hirschmilch.de:7000/progressive.aac";
        }
        {
          name = "Hirschmilch Psytrance // Electro";
          url = "http://hirschmilch.de:7000/psytrance.aac";
        }
        {
          name = "Hirschmilch Techno // Electro";
          url = "https://hirschmilch.de:7000/techno.aac";
        }
        {
          name = "Radio Nova // Generalist";
          url = "http://novazz.ice.infomaniak.ch/novazz-128.mp3";
        }
        {
          name = "France Info // Info";
          url = "http://direct.franceinfo.fr/live/franceinfo-midfi.mp3";
        }
      ];

    };
  };

  services.resolved = {
    extraConfig = ''
      MulticastDNS=no
    '';
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
