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

  # Fix nixos build limits
  systemd.settings.Manager.DefaultLimitNOFILE = "8192:524288";

  # Host information
  homelab = {
    domain = "ma-cabane.net";
    domainEmailAdmin = "brunoadele+admin@gmail.com";
    stmpAccountUsername = "brunoadele@gmail.com";

    nameServer = "192.168.254.154";
    host = {
      hostname = config.homelab.host.hostname;
      description = "Constellation private server";
      interface = "enp3s0";
      address = targetIP;
      gateway = "192.168.254.254";

      nproc = 16;
    };

    features = {
      homelab-summary.enable = true;

      acme.enable = true;
      acme.email = config.homelab.domainEmailAdmin;
      acme.dnsProvider = "hetzner";

      authentik.enable = true;
      authentik.openFirewall = true;
      authentik.serviceDomain = "douane.${config.homelab.domain}";

      blocky.enable = true;
      blocky.openFirewall = true;
      blocky.enableMonitoring = true;
      blocky.serviceDomain = "stop-pub.${config.homelab.domain}";

      gatus.enable = true;
      gatus.openFirewall = true;

      goaccess.enable = true;
      goaccess.openFirewall = true;
      goaccess.serviceDomain = "portique.${config.homelab.domain}";

      grafana.enable = true;
      grafana.openFirewall = true;
      grafana.serviceDomain = "lampiotes.${config.homelab.domain}";

      homepage-dashboard.enable = true;
      homepage-dashboard.openFirewall = true;
      homepage-dashboard.serviceDomain = "labrique.${config.homelab.domain}";

      it-tools.enable = true;
      it-tools.openFirewall = true;

      linkding.enable = true;
      linkding.openFirewall = true;

      lldap.enable = true;
      lldap.ldapDomain = "dc=ma-cabane,dc=lan";
      lldap.openFirewall = true;

      shaarli.enable = true;
      shaarli.openFirewall = true;

      victoriametrics.enable = true;
      victoriametrics.openFirewall = true;
      victoriametrics.serviceDomain = "sondes.${config.homelab.domain}";

      wastebin.enable = true;
      wastebin.openFirewall = true;

      grist.enable = true;
      grist.openFirewall = true;

      radio.enable = true;
      radio.openFirewall = true;
      radio.stations = [
        {
          name = "Hirschmilch Chillout";
          url = "http://hirschmilch.de:7000/chillout.mp3";
        }
        {
          name = "Radio Paradise";
          url = "http://stream-uk1.radioparadise.com/aac-320";
        }
        {
          name = "1 FM Reggae";
          url = "http://strm112.1.fm/reggae_mobile_mp3";
        }
        {
          name = "Platine 45";
          url = "https://ecmanager.pro-fhi.net:1710/;?type=http&nocache=1705079530?x=170507953?nocache=88806";
        }
        {
          name = "Radio Nova";
          url = "http://novazz.ice.infomaniak.ch/novazz-128.mp3";
        }
        {
          name = "Mouv";
          url = "http://icecast.radiofrance.fr/mouv-hifi.aac";
        }
        {
          name = "Mouv RnB and Soul";
          url = "https://icecast.radiofrance.fr/mouvrnb-hifi.aac";
        }
        {
          name = "Mouv Rap Francais";
          url = "https://icecast.radiofrance.fr/mouvrapfr-hifi.aac";
        }
        {
          name = "Mouv - Rap US";
          url = "https://icecast.radiofrance.fr/mouvrapus-hifi.aac";
        }
        {
          name = "Mouv - 100 Mix";
          url = "https://icecast.radiofrance.fr/mouv100p100mix-hifi.aac";
        }
        {
          name = "Mouv Classics";
          url = "https://icecast.radiofrance.fr/mouvclassics-hifi.aac";
        }
        {
          name = "SUNSET JAZZ RADIO";
          url = "https://radio2.vip-radios.fm:18077/stream-mp3-SunsetJazz";
        }
        {
          name = "Adroit Jazz Underground";
          url = "https://icecast.walmradio.com:8443/jazz";
        }
        {
          name = "Hirschmilch Organic House";
          url = "https://hirschmilch.de:7000/organic-house.aac";
        }
        {
          name = "Hirschmilch Electronic";
          url = "https://hirschmilch.de:7000/electronic.aac";
        }
        {
          name = "Hirschmilch Prog-House";
          url = "http://hirschmilch.de:7000/prog-house.aac";
        }
        {
          name = "Hirschmilch Progressive";
          url = "http://hirschmilch.de:7000/progressive.aac";
        }
        {
          name = "Hirschmilch Psytrance";
          url = "http://hirschmilch.de:7000/psytrance.aac";
        }
        {
          name = "Hirschmilch Techno";
          url = "https://hirschmilch.de:7000/techno.aac";
        }
      ];

    };
  };

  # Static networking configuration
  services.resolved = {
    enable = true;

    # disable stub listener to avoid port conflict with blocky DNS
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  networking = {
    enableIPv6 = false;

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

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${targetIP}";
}
