{ lib, config, ... }:
with lib;
with types;

let
  helpers = import ./helpers.nix { inherit lib; };
  inherit (helpers) mkFeatureOptions mkPodmanAliases;

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
        type = str;
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

    homelab.nameServer = mkOption {
      type = str;
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
      blocky = {
        appId = 1;
        httpPort = 10001;
      };
      step-ca = {
        appId = 2;
        httpPort = 10002;
      };
      lldap = {
        appId = 3;
        httpPort = 10003;
      };
      grafana = {
        appId = 4;
        httpPort = 10004;
      };
      victoriametrics = {
        appId = 5;
        httpPort = 10005;
      };
      homepage = {
        appId = 6;
        httpPort = 10006;
      };
      homelab-summary = {
        appId = 7;
        httpPort = 10007;
      };
    };

    # Export the helper functions so feature modules can use them
    _module.args.mkFeatureOptions = mkFeatureOptions;
    _module.args.mkPodmanAliases = mkPodmanAliases;
  };
}
