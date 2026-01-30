{ lib, config, ... }:
with lib;
with types;

let
  helpers = import ./helpers.nix { inherit lib; };
  inherit (helpers) mkFeatureOptions mkPodmanAliases mkServiceAliases;

  hostOptions =
    with lib;
    with types;
    {

      hostname = mkOption {
        type = str;
        description = ''
          Host hostname
        '';
      };

      description = mkOption {
        type = str;
        default = "";
        description = ''
          Host description
        '';
      };

      interface = mkOption {
        type = str;
        description = ''
          Network interface name
        '';
      };

      address = mkOption {
        type = str;
        description = ''
          IP address
        '';
      };

      gateway = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          Gateway address
        '';
      };

      nproc = mkOption {
        type = int;
        default = 0;
        description = ''
          Nb logical CPU
        '';
      };
    };
in
{

  options = {
    homelab.domain = mkOption {
      type = str;
      default = "homelab.local";
      description = "Default domain name for homelab";
    };

    homelab.domainEmailAdmin = mkOption {
      type = str;
      default = "admin@${config.homelab.domain}";
    };

    homelab.stmpAccountUsername = mkOption {
      type = str;
      default = "admin@${config.homelab.domain}";
    };

    homelab.nameServer = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        host or Ip for the main name server
      '';
    };

    homelab.host = mkOption {
      type = submodule [ { options = hostOptions; } ];
      description = "Host configuration";
    };

    homelab.alias = mkOption {
      type = listOf str;
      default = { };
      description = ''
        Aliases for this host
      '';
    };

    homelab.podmanBaseStorage = mkOption {
      type = str;
      default = "/data/podman";
      description = ''
        Base storage path for podman volumes
      '';
    };

    homelab.portRegistry = mkOption {
      type = attrs;
      description = ''
        Central registry of application IDs and their corresponding ports.
        Each feature gets a unique appId, and the HTTP port is calculated as 10000 + appId.
        This ensures no port conflicts across features.
      '';
    };

    # homelab.features is an open attribute set
    # Individual feature modules define their own options under homelab.features.<name>
    # They should use the mkFeatureOptions helper to ensure common options are defined
    # This allows modules to extend homelab.features dynamically
  };

  config = {
    # Central port registry with predefined appIds
    homelab.portRegistry = {
      blocky.appId = 0;
      lldap.appId = 10;
      grafana.appId = 20;
      victoriametrics.appId = 30;
      homepage-dashboard.appId = 40;
      homelab-summary.appId = 50;
      gatus.appId = 60;
      goaccess.appId = 70;
      wastebin.appId = 80;
      it-tools.appId = 90;
      linkding.appId = 100;
      shaarli.appId = 110;
      radio.appId = 120;
      grist.appId = 130;
      authentik.appId = 140;
      step-ca.appId = 150;
      pawtunes.appId = 160;
      miniflux.appId = 170;
      authelia.appId = 180;
      dokuwiki.appId = 190;
      kanidm.appId = 200;
    };

    # Export the helper functions so feature modules can use them
    _module.args.mkFeatureOptions = mkFeatureOptions;
    _module.args.mkPodmanAliases = mkPodmanAliases;
    _module.args.mkServiceAliases = mkServiceAliases;
  };
}
