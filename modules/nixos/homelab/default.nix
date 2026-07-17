args@{
  lib,
  config,
  ...
}:
with lib;
with types;

let
  sharedDomainsCatalog = args.sharedDomainsCatalog or { };
  isSharedDomainsCatalogEval = args.isSharedDomainsCatalogEval or false;
  helpers = import ./helpers.nix { inherit lib; };
  inherit (helpers) mkFeatureOptions mkPodmanAliases mkServiceAliases;

  vlanOptions =
    with lib;
    with types;
    {
      name = mkOption {
        type = str;
        description = ''
          VLAN interface name
        '';
      };

      id = mkOption {
        type = int;
        description = ''
          VLAN identifier
        '';
      };
    };

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

  integrationOptions =
    with lib;
    with types;
    {
      displayName = mkOption {
        type = str;
        description = "Human-readable service name.";
      };

      category = mkOption {
        type = str;
        description = "Service category used by aggregations.";
      };

      icon = mkOption {
        type = str;
        description = "Service icon identifier.";
      };

      description = mkOption {
        type = str;
        default = "";
        description = "Short service description.";
      };

      homepage = mkOption {
        type = nullOr attrs;
        default = null;
        description = "Homepage integration published by this service.";
      };

      gatus = mkOption {
        type = nullOr attrs;
        default = null;
        description = "Gatus integration published by this service.";
      };

      victoriametrics = mkOption {
        type = nullOr attrs;
        default = null;
        description = "VictoriaMetrics scrape configuration published by this service.";
      };

      grafana = mkOption {
        type = nullOr attrs;
        default = null;
        description = "Grafana provisioning configuration published by this service.";
      };
    };

  domainEntryOptions =
    with lib;
    with types;
    {
      domain = mkOption {
        type = str;
        description = "Published DNS name.";
      };

      service = mkOption {
        type = str;
        description = "Feature name owning this domain.";
      };

      host = mkOption {
        type = str;
        description = "Host name publishing this domain.";
      };

      registerScope = mkOption {
        type = listOf str;
        default = [ ];
        description = "DNS registration scopes for this domain.";
      };

      enabled = mkOption {
        type = bool;
        default = true;
        description = "Whether this domain entry is active.";
      };

      targetAddress = mkOption {
        type = nullOr str;
        default = null;
        description = "IPv4 address published for this domain.";
      };
    };

  resolveInterfaceIPv4Addresses =
    interfaceName:
    map (address: address.address) (attrByPath [ interfaceName "ipv4" "addresses" ] [ ] config.networking.interfaces);

  resolveFeatureListenAddresses =
    featureName: listenInterfaces:
    lib.unique (concatMap resolveInterfaceIPv4Addresses listenInterfaces);

  enabledFeatureAttrs = filterAttrs (_: featureCfg: featureCfg.enable or false) (config.homelab.features or { });

  featureDomainEntries =
    mapAttrs'
      (
        featureName: featureCfg:
        nameValuePair featureName {
          domain = featureCfg.serviceDomain;
          service = featureName;
          host = config.networking.hostName;
          registerScope = featureCfg.registerScope or [ ];
          enabled = true;
          targetAddress =
            if featureCfg.dnsTargetAddress or null != null then
              featureCfg.dnsTargetAddress
            else
              let
                resolvedAddresses = resolveFeatureListenAddresses featureName (featureCfg.listenInterfaces or [ ]);
              in
              if length resolvedAddresses == 1 then head resolvedAddresses else config.homelab.host.address;
        }
      )
      (filterAttrs (_: featureCfg: featureCfg ? serviceDomain) enabledFeatureAttrs);

  featureListenAssertions =
    flatten (
      mapAttrsToList (
        featureName: featureCfg:
        let
          listenInterfaces = featureCfg.listenInterfaces or [ ];
          resolvedAddresses = resolveFeatureListenAddresses featureName listenInterfaces;
          requiresExplicitDnsTarget =
            listenInterfaces != [ ]
            && (featureCfg.registerScope or [ ]) != [ ]
            && (featureCfg.dnsTargetAddress or null == null)
            && length resolvedAddresses != 1;
        in
        (map (interfaceName: {
          assertion = hasAttr interfaceName config.networking.interfaces;
          message = "homelab.features.${featureName}.listenInterfaces references unknown interface '${interfaceName}'";
        }) listenInterfaces)
        ++ (map (interfaceName: {
          assertion = resolveInterfaceIPv4Addresses interfaceName != [ ];
          message = "homelab.features.${featureName}.listenInterfaces interface '${interfaceName}' has no IPv4 address configured";
        }) listenInterfaces)
        ++ optional requiresExplicitDnsTarget {
          assertion = false;
          message = "homelab.features.${featureName}.dnsTargetAddress must be set when listenInterfaces resolves to multiple IPv4 addresses";
        }
      ) enabledFeatureAttrs
    );
in
{

  options = {
    homelab.domain = mkOption {
      type = str;
      default = "ma-cabane.net";
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
      default = [ ];
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

    homelab.vlans = mkOption {
      type = attrsOf (submodule [ { options = vlanOptions; } ]);
      default = { };
      description = ''
        Global VLAN catalog shared across machines.
      '';
    };

    homelab.integrations.services = mkOption {
      type = attrsOf (submodule [ { options = integrationOptions; } ]);
      default = { };
      description = ''
        Cross-host service integrations consumed by dashboarding, health checks,
        and monitoring features.
      '';
    };

    homelab.domains.localEntries = mkOption {
      type = attrsOf (submodule [ { options = domainEntryOptions; } ]);
      default = { };
      description = ''
        Structured registry of domains published by the current machine.
      '';
    };

    homelab.domains.sharedEntries = mkOption {
      type = attrsOf (attrsOf (submodule [ { options = domainEntryOptions; } ]));
      default = { };
      description = ''
        Structured registry of domains shared across machines, keyed by machine.
      '';
    };

    # homelab.features is an open attribute set
    # Individual feature modules define their own options under homelab.features.<name>
    # They should use the mkFeatureOptions helper to ensure common options are defined
    # This allows modules to extend homelab.features dynamically
  };

  config = {
    assertions = featureListenAssertions;

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
      zitadel.appId = 210;
    };

    homelab.vlans = {
      adm = {
        name = "adm";
        id = 240;
      };
      lan = {
        name = "lan";
        id = 254;
      };
      dmz = {
        name = "dmz";
        id = 32;
      };
      iot = {
        name = "iot";
        id = 40;
      };
    };

    homelab.domains.localEntries = featureDomainEntries;
    homelab.domains.sharedEntries = if isSharedDomainsCatalogEval then { } else sharedDomainsCatalog;

    # Export the helper functions so feature modules can use them
    _module.args.mkFeatureOptions = mkFeatureOptions;
    _module.args.mkPodmanAliases = mkPodmanAliases;
    _module.args.mkServiceAliases = mkServiceAliases;
    _module.args.resolveListenInterfaceAddresses = resolveFeatureListenAddresses;
  };
}
