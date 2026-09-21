args@{
  lib,
  config,
  ...
}:
with lib;
with types;

let
  sharedDomainsCatalog = args.sharedDomainsCatalog or { };
  sharedHostsCatalog = args.sharedHostsCatalog or { };
  sharedIntegrationsCatalog = args.sharedIntegrationsCatalog or { };
  isSharedDomainsCatalogEval = args.isSharedDomainsCatalogEval or false;
  isSharedHostsCatalogEval = args.isSharedHostsCatalogEval or false;
  isSharedIntegrationsCatalogEval = args.isSharedIntegrationsCatalogEval or false;
  helpers = import ./helpers.nix { inherit lib; };
  inherit (helpers)
    mkFeatureOptions
    mkPodmanAliases
    mkServiceAliases
    mkGrafanaDashboardProvider
    ;
  mkFirewallInterfaces = helpers.mkFirewallInterfaces;

  vlanOptions =
    vlanName: vlanConfig:
    with lib;
    with types;
    {
      name = mkOption {
        type = str;
        default = vlanName;
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

      prefixDomain = mkOption {
        type = str;
        default = vlanName;
        description = ''
          DNS prefix attached to this VLAN.
          Ex: "mgmt"
        '';
      };

      dhcpServerIp = mkOption {
        type = nullOr str;
        default = "192.168.${toString vlanConfig.id}.254";
        description = ''
          DHCP server IPv4 address for this VLAN.
        '';
      };
    };

  hostAddressOptions =
    with lib;
    with types;
    {
      interface = mkOption {
        type = str;
        description = ''
          Network interface carrying this address.
        '';
      };

      address = mkOption {
        type = str;
        description = ''
          IPv4 address.
        '';
      };

      prefixLength = mkOption {
        type = nullOr int;
        default = null;
        description = ''
          IPv4 prefix length when the address is statically configured.
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
          Legacy primary IP address. Prefer homelab.host.addresses for new code.
        '';
      };

      addresses = mkOption {
        type = attrsOf (submodule [ { options = hostAddressOptions; } ]);
        default = { };
        description = ''
          Named host addresses by network role, for example lan, mgmt, infra,
          dmz, iot, public, or default.
        '';
      };

      defaultAddressRef = mkOption {
        type = str;
        default = "default";
        description = ''
          Address role used when no more specific address is requested.
        '';
      };

      managementAddressRef = mkOption {
        type = str;
        default = "default";
        description = ''
          Address role used for administrative access to this machine.
        '';
      };

      publicAddressRef = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          Address role used for public access to this machine, when any.
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

      vmalert = mkOption {
        type = nullOr attrs;
        default = null;
        description = "VictoriaMetrics vmalert rule configuration published by this service.";
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

  getHostAddress =
    addressRef:
    if addressRef == null then null else config.homelab.host.addresses.${addressRef} or null;

  hostDefaultAddress = getHostAddress config.homelab.host.defaultAddressRef;
  hostManagementAddress = getHostAddress config.homelab.host.managementAddressRef;
  hostPublicAddress = getHostAddress config.homelab.host.publicAddressRef;

  hostAddressAssertions =
    let
      checkAddressRef =
        refName: addressRef:
        optional (addressRef != null && !hasAttr addressRef config.homelab.host.addresses) {
          assertion = false;
          message = "homelab.host.${refName} references unknown address '${addressRef}'.";
        };
    in
    checkAddressRef "defaultAddressRef" config.homelab.host.defaultAddressRef
    ++ checkAddressRef "managementAddressRef" config.homelab.host.managementAddressRef
    ++ checkAddressRef "publicAddressRef" config.homelab.host.publicAddressRef;

  resolveSharedHostAddressEntry =
    machineName: addressSelector:
    let
      machineExists = hasAttr machineName config.homelab.hosts.sharedHosts;
      sharedHost =
        if machineExists then config.homelab.hosts.sharedHosts.${machineName} else { };
      host = sharedHost.host or { };
      addresses = host.addresses or { };
      interfaces = sharedHost.interfaces or { };
      defaultAddressRef = host.defaultAddressRef or null;
      managementAddressRef = host.managementAddressRef or null;
      publicAddressRef = host.publicAddressRef or null;
      addressRef =
        if addressSelector == "default" && defaultAddressRef != null then
          defaultAddressRef
        else if addressSelector == "management" && managementAddressRef != null then
          managementAddressRef
        else if addressSelector == "public" && !(hasAttr addressSelector addresses) && publicAddressRef != null then
          publicAddressRef
        else
          addressSelector;
      roleAddress = addresses.${addressRef} or null;
      interfaceAddresses = attrByPath [ addressSelector "ipv4" "addresses" ] [ ] interfaces;
      interfaceAddress =
        if interfaceAddresses == [ ] then
          null
        else
          let
            address = head interfaceAddresses;
          in
          {
            inherit addressSelector;
            addressRef = null;
            source = "interface";
            interface = addressSelector;
            address = address.address;
            prefixLength = address.prefixLength or null;
          };
      namedInterfaceAddressEntries = filter (
        addressEntry: (addressEntry.value.interface or null) == addressSelector
      ) (mapAttrsToList (name: value: { inherit name value; }) addresses);
      namedInterfaceAddress =
        if namedInterfaceAddressEntries == [ ] then
          null
        else
          let
            addressEntry = head namedInterfaceAddressEntries;
          in
          addressEntry.value
          // {
            inherit addressSelector;
            addressRef = addressEntry.name;
            source = "address-interface";
          };
      resolvedAddress =
        if roleAddress != null then
          roleAddress
          // {
            inherit addressSelector addressRef;
            source = "address-role";
          }
        else if interfaceAddress != null then
          interfaceAddress
        else
          namedInterfaceAddress;
      availableMachines = concatStringsSep ", " (attrNames config.homelab.hosts.sharedHosts);
      availableAddressRefs = concatStringsSep ", " (attrNames addresses);
      availableInterfaces = concatStringsSep ", " (attrNames interfaces);
    in
    if !machineExists then
      throw "homelab.hosts.sharedHosts references unknown machine '${machineName}'. Available machines: ${availableMachines}."
    else if resolvedAddress == null then
      throw "homelab.hosts.sharedHosts.${machineName} has no address role or interface '${addressSelector}'. Available roles: ${availableAddressRefs}; interfaces: ${availableInterfaces}."
    else
      resolvedAddress;

  resolveSharedHostAddress =
    machineName: addressSelector: (resolveSharedHostAddressEntry machineName addressSelector).address;

  mkFirewallAllowedSources =
    allow:
    mapAttrsToList (
      machineName: addressSelector:
      (resolveSharedHostAddressEntry machineName addressSelector)
      // {
        inherit machineName;
      }
    ) allow;

  mkFirewallExtraCommands =
    cfg: ports: allowedSources:
    let
      iptables = "${config.networking.firewall.package}/bin/iptables";
    in
    concatStringsSep "\n" (
      flatten (
        map (
          listenInterface:
          map (
            source:
            map (
              port:
              "${iptables} -w -A nixos-fw -i ${listenInterface} -s ${source.address} -p tcp --dport ${toString port} -j ACCEPT"
            ) ports
          ) allowedSources
        ) cfg.listenInterfaces
      )
    );

  mkFirewallExtraInputRules =
    cfg: ports: allowedSources:
    concatStringsSep "\n" (
      flatten (
        map (
          listenInterface:
          map (
            source:
            map (
              port:
              ''iifname "${listenInterface}" ip saddr ${source.address} tcp dport ${toString port} accept''
            ) ports
          ) allowedSources
        ) cfg.listenInterfaces
      )
    );

  mkFirewall =
    cfg: ports:
    let
      allow = cfg.allow or { };
      allowedSources = mkFirewallAllowedSources allow;
      hasRestrictedSources = allowedSources != [ ];
    in
    mkMerge [
      {
        interfaces = mkIf (cfg.openFirewall && !hasRestrictedSources) (mkFirewallInterfaces cfg ports);
      }
      (mkIf hasRestrictedSources {
        extraCommands = mkIf (
          !config.networking.nftables.enable
        ) (mkFirewallExtraCommands cfg ports allowedSources);
        extraInputRules = mkIf (
          config.networking.nftables.enable
        ) (mkFirewallExtraInputRules cfg ports allowedSources);
      })
    ];

  resolveInterfaceIPv4Addresses =
    interfaceName:
    lib.unique (
      (map (address: address.address) (
        attrByPath [ interfaceName "ipv4" "addresses" ] [ ] config.networking.interfaces
      ))
      ++ optional (interfaceName == config.homelab.host.interface) config.homelab.host.address
    );

  resolveInterfacePrimaryIPv4Address =
    interfaceName:
    let
      addresses = attrByPath [ interfaceName "ipv4" "addresses" ] [ ] config.networking.interfaces;
    in
    if addresses != [ ] then
      [ (head addresses).address ]
    else
      optional (interfaceName == config.homelab.host.interface) config.homelab.host.address;

  resolveFeatureListenAddresses =
    featureName: listenInterfaces:
    let
      resolveFeatureListenAddress =
        interfaceName:
        let
          vlanNames = attrNames (
            filterAttrs (_: vlanCfg: interfaceName == "br-${vlanCfg.name}") config.homelab.vlans
          );
          vlanName = if length vlanNames == 1 then head vlanNames else null;
          serviceAddress =
            if
              vlanName != null && hasAttrByPath [ vlanName featureName ] config.homelab.serviceAddressRegistry
            then
              config.homelab.serviceAddressRegistry.${vlanName}.${featureName}
            else
              null;
          interfaceAddresses = resolveInterfaceIPv4Addresses interfaceName;
        in
        if serviceAddress != null && elem serviceAddress interfaceAddresses then
          [ serviceAddress ]
        else
          resolveInterfacePrimaryIPv4Address interfaceName;
    in
    lib.unique (concatMap resolveFeatureListenAddress listenInterfaces);

  resolveIntegrationListenAddresses =
    featureName: listenInterfaces:
    lib.unique (
      concatMap (
        interfaceName:
        if interfaceName == "lo" then
          [ "127.0.0.1" ]
        else
          resolveFeatureListenAddresses featureName [ interfaceName ]
      ) listenInterfaces
    );

  selectSharedIntegrationServices =
    integrationType: collectIntegrations:
    listToAttrs (
      flatten (
        mapAttrsToList (
          machineName: serviceNames:
          let
            machineServices = config.homelab.integrations.sharedServices.${machineName} or { };
          in
          map (
            serviceName:
            nameValuePair "${machineName}-${serviceName}" (machineServices.${serviceName} or { })
          ) serviceNames
        ) collectIntegrations
      )
    );

  mkSharedIntegrationAssertions =
    consumerName: integrationTypes: collectIntegrations:
    flatten (
      mapAttrsToList (
        machineName: serviceNames:
        let
          machineExists = hasAttr machineName config.homelab.integrations.sharedServices;
          machineServices =
            if machineExists then config.homelab.integrations.sharedServices.${machineName} else { };
        in
        optional (!machineExists) {
          assertion = false;
          message = "homelab.features.${consumerName}.collectIntegrations references unknown machine '${machineName}'.";
        }
        ++ flatten (
          map (
            serviceName:
            let
              serviceExists = hasAttr serviceName machineServices;
              service = if serviceExists then machineServices.${serviceName} else { };
              integrationExists =
                serviceExists && any (integrationType: (service.${integrationType} or null) != null) integrationTypes;
            in
            optional (!serviceExists) {
              assertion = false;
              message = "homelab.features.${consumerName}.collectIntegrations.${machineName} references unpublished service '${serviceName}'.";
            }
            ++ optional (serviceExists && !integrationExists) {
              assertion = false;
              message = "homelab.features.${consumerName}.collectIntegrations.${machineName}.${serviceName} does not publish integration type ${concatStringsSep "/" integrationTypes}.";
            }
          ) serviceNames
        )
      ) collectIntegrations
    );

  allocateIPForService =
    vlanName: serviceName: config.homelab.serviceAddressRegistry.${vlanName}.${serviceName};

  allocateIPv4AddressesForServices =
    vlanName: serviceNames:
    map (serviceName: {
      address = allocateIPForService vlanName serviceName;
      prefixLength = 24;
    }) serviceNames;

  enabledFeatureAttrs = filterAttrs (_: featureCfg: featureCfg.enable or false) (
    config.homelab.features or { }
  );

  featureDomainEntries = mapAttrs' (
    featureName: featureCfg:
    nameValuePair featureName {
      domain = featureCfg.serviceDomain;
      service = featureName;
      host = config.networking.hostName;
      registerScope = featureCfg.registerScope or [ ];
      enabled = true;
      targetAddress =
        if (featureCfg.registerScope or [ ]) == [ ] then
          null
        else if (featureCfg.dnsTargetAddress or null) != null then
          featureCfg.dnsTargetAddress
        else
          let
            resolvedAddresses = resolveFeatureListenAddresses featureName (featureCfg.listenInterfaces or [ ]);
          in
          if length resolvedAddresses == 1 then head resolvedAddresses else config.homelab.host.address;
    }
  ) (filterAttrs (_: featureCfg: featureCfg ? serviceDomain) enabledFeatureAttrs);

  hostVlanDomainEntries = listToAttrs (
    flatten (
      mapAttrsToList (
        vlanName: vlanCfg:
        let
          bridgeName = "br-${vlanCfg.name}";
          bridgeAddresses = resolveInterfaceIPv4Addresses bridgeName;
          vlanDomain =
            if vlanCfg.prefixDomain == "" then
              config.homelab.domain
            else
              "${vlanCfg.prefixDomain}.${config.homelab.domain}";
        in
        optional (hasAttr bridgeName config.networking.bridges && length bridgeAddresses == 1) (
          nameValuePair "host-${vlanName}" {
            domain = "${config.networking.hostName}.${vlanDomain}";
            service = "host";
            host = config.networking.hostName;
            registerScope = [ "private" ];
            enabled = true;
            targetAddress = head bridgeAddresses;
          }
        )
      ) config.homelab.vlans
    )
  );

  featureListenAssertions = flatten (
    mapAttrsToList (
      featureName: featureCfg:
      let
        listenInterfaces = featureCfg.listenInterfaces or [ ];
        resolvedAddresses = resolveFeatureListenAddresses featureName listenInterfaces;
        hasRestrictedSources = (featureCfg.allow or { }) != { };
        requiresExplicitDnsTarget =
          listenInterfaces != [ ]
          && (featureCfg.registerScope or [ ]) != [ ]
          && (featureCfg.dnsTargetAddress or null == null)
          && length resolvedAddresses != 1;
        requiresExplicitListenInterfaces =
          ((featureCfg.openFirewall or false) || hasRestrictedSources) && listenInterfaces == [ ];
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
      ++ optional requiresExplicitListenInterfaces {
        assertion = false;
        message = "homelab.features.${featureName}.listenInterfaces must be set when openFirewall or allow is enabled";
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

    homelab.hosts.localHost = mkOption {
      type = attrs;
      default = { };
      description = ''
        Structured host information published by the current machine.
      '';
    };

    homelab.hosts.sharedHosts = mkOption {
      type = attrsOf attrs;
      default = { };
      description = ''
        Structured host information shared across machines, keyed by machine.
      '';
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

    homelab.serviceAddressRegistry = mkOption {
      type = attrs;
      description = ''
        Central registry of service IPv4 addresses derived from application IDs.
        Each service gets a stable IPv4 address per VLAN when the VLAN uses the
        192.168.<vlan id>.0/24 addressing convention.
      '';
    };

    homelab.vlans = mkOption {
      type = attrsOf (submodule [ ({ name, config, ... }: { options = vlanOptions name config; }) ]);
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

    homelab.integrations.sharedServices = mkOption {
      type = attrsOf (attrsOf (submodule [ { options = integrationOptions; } ]));
      default = { };
      description = ''
        Cross-host service integrations shared across machines, keyed by machine.
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
    assertions = featureListenAssertions ++ hostAddressAssertions;

    homelab.host.addresses.${config.homelab.host.defaultAddressRef} = mkDefault {
      inherit (config.homelab.host) address interface;
      prefixLength = null;
    };

    homelab.hosts.localHost = {
      host = {
        inherit (config.homelab.host)
          addresses
          defaultAddressRef
          description
          gateway
          hostname
          interface
          managementAddressRef
          nproc
          publicAddressRef
          ;
        defaultAddress = if hostDefaultAddress == null then null else hostDefaultAddress.address;
        defaultInterface = if hostDefaultAddress == null then null else hostDefaultAddress.interface;
        managementAddress = if hostManagementAddress == null then null else hostManagementAddress.address;
        managementInterface = if hostManagementAddress == null then null else hostManagementAddress.interface;
        publicAddress = if hostPublicAddress == null then null else hostPublicAddress.address;
        publicInterface = if hostPublicAddress == null then null else hostPublicAddress.interface;
      };
      interfaces = mapAttrs (_: interfaceCfg: {
        ipv4.addresses = interfaceCfg.ipv4.addresses or [ ];
        ipv6.addresses = interfaceCfg.ipv6.addresses or [ ];
      }) config.networking.interfaces;
      inherit (config.networking) bridges vlans;
    };

    homelab.hosts.sharedHosts = if isSharedHostsCatalogEval then { } else sharedHostsCatalog;

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
      mikrotik.appId = 220;
      victorialogs.appId = 230;
      vector.appId = 240;
      netbird.appId = 250; # Use port range
      #      next_free_.appId = 400;
    };

    # Compute the serviceAddressRegistry based on the portRegistry and VLAN IDs
    homelab.serviceAddressRegistry = mapAttrs (
      _: vlanCfg:
      mapAttrs (
        _: portCfg: "192.168.${toString vlanCfg.id}.${toString (20 + builtins.div portCfg.appId 10)}"
      ) config.homelab.portRegistry
    ) config.homelab.vlans;

    homelab.vlans = {
      mgmt = {
        id = 240;
      };
      lan = {
        id = 254;
        prefixDomain = "";
      };
      dmz = {
        id = 32;
      };
      infra = {
        id = 244;
      };
      iot = {
        id = 40;
      };
    };

    homelab.domains.localEntries = featureDomainEntries // hostVlanDomainEntries;
    homelab.domains.sharedEntries = if isSharedDomainsCatalogEval then { } else sharedDomainsCatalog;
    homelab.integrations.sharedServices =
      if isSharedIntegrationsCatalogEval then { } else sharedIntegrationsCatalog;

    # Export the helper functions so feature modules can use them
    _module.args.mkFeatureOptions = mkFeatureOptions;
    _module.args.mkPodmanAliases = mkPodmanAliases;
    _module.args.mkServiceAliases = mkServiceAliases;
    _module.args.mkGrafanaDashboardProvider = mkGrafanaDashboardProvider;
    _module.args.mkFirewall = mkFirewall;
    _module.args.mkFirewallInterfaces = mkFirewallInterfaces;
    _module.args.resolveListenInterfaceAddresses = resolveFeatureListenAddresses;
    _module.args.resolveIntegrationListenAddresses = resolveIntegrationListenAddresses;
    _module.args.resolveSharedHostAddress = resolveSharedHostAddress;
    _module.args.resolveSharedHostAddressEntry = resolveSharedHostAddressEntry;
    _module.args.selectSharedIntegrationServices = selectSharedIntegrationServices;
    _module.args.mkSharedIntegrationAssertions = mkSharedIntegrationAssertions;
    _module.args.allocateIPForService = allocateIPForService;
    _module.args.allocateIPv4AddressesForServices = allocateIPv4AddressesForServices;
  };
}
