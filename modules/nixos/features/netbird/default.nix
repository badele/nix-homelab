{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkFirewall,
  mkGrafanaDashboardProvider,
  mkServiceAliases,
  resolveIntegrationListenAddresses,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;
let
  appName = "netbird";
  appDisplayName = "NetBird";
  appCategory = "Core Services";
  appIcon = "netbird";
  appPlatform = "nixos";
  appDescription = "WireGuard-based private mesh network with access controls";
  appUrl = "https://github.com/netbirdio/netbird";
  appPinnedVersion = pkgs.netbird.version;

  cfg = config.homelab.features.${appName};
  publishCfg = cfg.publishIntegrations;
  publishMetricsCfg = publishCfg.victoriametrics;
  appId = config.homelab.portRegistry.${appName}.appId;
  oidcScopes = "openid profile email offline_access api";

  managementPort = 10000 + appId;
  signalPort = managementPort + 1;
  managementMetricsPort = managementPort + 2;
  signalMetricsPort = managementPort + 3;
  defaultTurnPort = managementPort + 4;
  defaultTurnRelayPortRange = {
    from = managementPort + 5;
    to = managementPort + 85;
  };
  defaultRelayPort = defaultTurnRelayPortRange.to + 1;
  relayMetricsPort = managementPort + 87;

  exposedURL = "https://${cfg.public.serviceDomain}";
  monitoringURL = exposedURL;
  managementInternalURL = "http://127.0.0.1:${toString cfg.public.managementPort}";
  signalInternalURL = "h2c://127.0.0.1:${toString cfg.public.signalPort}";
  signalWebsocketInternalURL = "http://127.0.0.1:${toString cfg.public.signalPort}";
  relayInternalURL = "http://127.0.0.1:${toString cfg.public.relayPort}";
  publishedMetricsListenInterfaces =
    if publishMetricsCfg.enable then
      filter (interfaceName: interfaceName != "lo") publishMetricsCfg.listenInterfaces
    else
      [ ];
  publishedMetricsAddresses =
    if publishMetricsCfg.enable then
      resolveIntegrationListenAddresses appName publishMetricsCfg.listenInterfaces
    else
      [ ];
  publishesPublicIntegration = publishCfg.homepage || publishCfg.gatus || publishMetricsCfg.enable;
  publishesAnyIntegration = publishesPublicIntegration || publishCfg.grafana;
  publishesRemoteMetrics = publishMetricsCfg.enable && publishedMetricsListenInterfaces != [ ];
  netbirdMetricsPorts = [
    cfg.public.managementMetricsPort
    cfg.public.signalMetricsPort
    cfg.public.relayMetricsPort
  ];
  metricsFirewallCfg = {
    openFirewall = false;
    listenInterfaces = publishedMetricsListenInterfaces;
    allow = cfg.public.metricsAllow;
  };
  mkPublishedMetricTarget =
    component: port:
    {
      targets = map (address: "${address}:${toString port}") publishedMetricsAddresses;
      labels = {
        instance = config.networking.hostName;
        machine = config.networking.hostName;
        service = appName;
        inherit component;
      };
    };

  enabledClients = filterAttrs (_: clientCfg: clientCfg.enable) cfg.clients;
  enabledClientValues = attrValues enabledClients;
  enabledGatewayClients = filter (clientCfg: clientCfg.gateway.enable) enabledClientValues;
  vlanNetwork = vlanCfg: "192.168.${toString vlanCfg.id}.0/24";
  inferGatewayVlans =
    clientCfg:
    attrNames (
      filterAttrs (_: vlanCfg: elem (vlanNetwork vlanCfg) clientCfg.gateway.networks) config.homelab.vlans
    );
  gatewayVlans =
    clientCfg:
    filter (vlanName: hasAttr vlanName config.homelab.vlans) (
      lib.unique (clientCfg.gateway.vlans ++ inferGatewayVlans clientCfg)
    );
  gatewayInterfaces =
    clientCfg: map (vlanName: "br-${config.homelab.vlans.${vlanName}.name}") (gatewayVlans clientCfg);
  enabledGatewayRoutingFeatures = lib.unique (
    map (clientCfg: clientCfg.gateway.routingFeatures) enabledGatewayClients
  );
  needsClientRouting =
    elem "client" enabledGatewayRoutingFeatures || elem "both" enabledGatewayRoutingFeatures;
  needsServerRouting =
    elem "server" enabledGatewayRoutingFeatures || elem "both" enabledGatewayRoutingFeatures;
  routingFeatures =
    if needsClientRouting && needsServerRouting then
      "both"
    else if needsClientRouting then
      "client"
    else if needsServerRouting then
      "server"
    else
      "none";
  parseManagementURL =
    url:
    let
      match = builtins.match "^(https?)://([^/]+)/*$" url;
    in
    if match == null then
      null
    else
      {
        scheme = elemAt match 0;
        host = elemAt match 1;
      };
  mkManagementURLConfig =
    url:
    let
      parsed = parseManagementURL url;
      defaultPort = if parsed.scheme == "http" then "80" else "443";
    in
    {
      Scheme = parsed.scheme;
      Opaque = "";
      User = null;
      Host =
        if builtins.match ".*:[0-9]+$" parsed.host != null then
          parsed.host
        else
          "${parsed.host}:${defaultPort}";
      Path = "";
      Fragment = "";
      RawQuery = "";
      RawPath = "";
      RawFragment = "";
      ForceQuery = false;
      OmitHost = false;
    };

  uniquePortOffsets = lib.unique (map (clientCfg: clientCfg.portOffset) enabledClientValues);

  coturnPasswordFile = config.clan.core.vars.generators.${appName}.files.coturn-password.path;
  relaySecretFile = config.clan.core.vars.generators.${appName}.files.relay-secret.path;
  relayStart = pkgs.writeShellScript "netbird-relay-start" ''
    set -euo pipefail
    export NB_AUTH_SECRET="$(cat ${relaySecretFile})"
    exec ${lib.getExe pkgs.netbird-relay} --metrics-port ${toString cfg.public.relayMetricsPort}
  '';
  oidcManagementClientSecretFile =
    if cfg.auth.managementClientSecretFile != null then
      cfg.auth.managementClientSecretFile
    else
      config.clan.core.vars.generators.${appName}.files.management-client-secret.path;

  resolveClientSetupKeyFile =
    clientName: clientCfg:
    if clientCfg.setupKeyFile != null then
      clientCfg.setupKeyFile
    else
      config.clan.core.vars.generators."${appName}-client-${clientName}".files.setup-key.path;

  mkInterfaceFirewall = listenInterfaces: firewallCfg: genAttrs listenInterfaces (_: firewallCfg);

  mkClientFirewall =
    clientCfg:
    mkIf clientCfg.openFirewall (
      mkInterfaceFirewall clientCfg.listenInterfaces {
        allowedUDPPorts = [ clientCfg.wireguardPort ];
      }
    );

  publicFirewall = mkIf cfg.public.openFirewall (
    mkInterfaceFirewall cfg.public.listenInterfaces {
      allowedTCPPorts = [
        443
        cfg.public.turnPort
      ];
      allowedUDPPorts = [ cfg.public.turnPort ];
      allowedUDPPortRanges = [ cfg.public.turnRelayPortRange ];
    }
  );

  clientFirewalls = mapAttrsToList (_: mkClientFirewall) enabledClients;
  gatewayForwardRules = concatMapStringsSep "\n" (
    clientCfg:
    concatMapStringsSep "\n" (gatewayInterface: ''
      iifname "${clientCfg.interface}" oifname "${gatewayInterface}" accept
      iifname "${gatewayInterface}" oifname "${clientCfg.interface}" ct state established,related accept
    '') (gatewayInterfaces clientCfg)
  ) enabledGatewayClients;
  mkNetbirdClient =
    clientName: clientCfg:
    nameValuePair clientName ({
      port = clientCfg.wireguardPort;
      interface = clientCfg.interface;
      name = clientName;
      openFirewall = false;
      openInternalFirewall = true;
      hardened = true;
      login = {
        enable = true;
        setupKeyFile = resolveClientSetupKeyFile clientName clientCfg;
      };
      environment =
        optionalAttrs (clientCfg.managementURL != "") {
          NB_MANAGEMENT_URL = clientCfg.managementURL;
        }
        // clientCfg.environment;
      config =
        optionalAttrs (clientCfg.managementURL != "") {
          ManagementURL = mkManagementURLConfig clientCfg.managementURL;
        }
        // clientCfg.config;
    });

  mkClientSetupKeyGenerators =
    clientName: clientCfg:
    let
      promptGeneratorName = "${appName}-client-${clientName}-setup-key";
      generatorName = "${appName}-client-${clientName}";
    in
    [
      (nameValuePair promptGeneratorName {
        prompts.setup-key = {
          description = "Please insert NetBird setup key for ${clientName}";
          persist = true;
        };
      })
      (nameValuePair generatorName {
        files.setup-key = { };
        dependencies = [ promptGeneratorName ];
        script = ''
          cat "$in/${promptGeneratorName}/setup-key" > "$out/setup-key"
        '';
      })
    ];
in
{
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      dnsDomain = mkOption {
        type = str;
        default = "netbird.${config.homelab.domain}";
        description = "Domain used for NetBird peer resolution.";
      };

      public = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "NetBird public control plane";

            serviceDomain = mkOption {
              type = str;
              default = "${appName}.${config.homelab.domain}";
              description = "NetBird public service domain name";
            };

            listenInterfaces = mkOption {
              type = listOf str;
              default = [ ];
              description = "Interfaces used to expose the NetBird control plane.";
            };

            registerScope = mkOption {
              type = listOf str;
              default = [ ];
              description = "DNS registration scopes for the NetBird control plane.";
            };

            dnsTargetAddress = mkOption {
              type = nullOr str;
              default = null;
              description = "Explicit IPv4 address published for the NetBird control plane.";
            };

            openFirewall = mkEnableOption "Open NetBird public ports on listenInterfaces";

            metricsAllow = mkOption {
              type = attrsOf str;
              default = { };
              description = "Remote machines allowed to reach NetBird public metrics ports.";
            };

            managementPort = mkOption {
              type = port;
              default = managementPort;
              description = "Internal NetBird management API port.";
            };

            signalPort = mkOption {
              type = port;
              default = signalPort;
              description = "Internal NetBird signal gRPC port.";
            };

            managementMetricsPort = mkOption {
              type = port;
              default = managementMetricsPort;
              description = "Internal NetBird management metrics port.";
            };

            signalMetricsPort = mkOption {
              type = port;
              default = signalMetricsPort;
              description = "Internal NetBird signal metrics port.";
            };

            relayPort = mkOption {
              type = port;
              default = defaultRelayPort;
              description = "Internal NetBird relay WebSocket port.";
            };

            relayMetricsPort = mkOption {
              type = port;
              default = relayMetricsPort;
              description = "Internal NetBird relay metrics port.";
            };

            turnPort = mkOption {
              type = port;
              default = defaultTurnPort;
              description = "Public STUN/TURN port advertised to NetBird clients.";
            };

            turnRelayPortRange = mkOption {
              type = submodule {
                options = {
                  from = mkOption {
                    type = port;
                    default = defaultTurnRelayPortRange.from;
                    description = "First UDP relay port used by coturn.";
                  };
                  to = mkOption {
                    type = port;
                    default = defaultTurnRelayPortRange.to;
                    description = "Last UDP relay port used by coturn.";
                  };
                };
              };
              default = defaultTurnRelayPortRange;
              description = "UDP relay port range used by coturn.";
            };

            management = mkOption {
              type = submodule {
                options = {
                  settings = mkOption {
                    type = attrs;
                    default = { };
                    description = "Extra NetBird management settings merged with homelab defaults.";
                  };

                  extraOptions = mkOption {
                    type = listOf str;
                    default = [ ];
                    description = "Extra command-line options passed to netbird-mgmt.";
                  };
                };
              };
              default = { };
              description = "Passthrough options for services.netbird.server.management.";
            };

            signal = mkOption {
              type = submodule {
                options.extraOptions = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Extra command-line options passed to netbird-signal.";
                };
              };
              default = { };
              description = "Passthrough options for services.netbird.server.signal.";
            };

            dashboard = mkOption {
              type = submodule {
                options.settings = mkOption {
                  type = attrs;
                  default = { };
                  description = "Extra dashboard settings merged with homelab defaults.";
                };
              };
              default = { };
              description = "Passthrough options for services.netbird.server.dashboard.";
            };
          };
        };
        default = { };
        description = "NetBird self-hosted control plane options.";
      };

      auth = mkOption {
        type = submodule {
          options = {
            provider = mkOption {
              type = enum [ "zitadel" ];
              default = "zitadel";
              description = "OIDC provider used by NetBird.";
            };

            issuerURL = mkOption {
              type = str;
              default = "https://${config.homelab.features.zitadel.serviceDomain}";
              description = "OIDC issuer URL.";
            };

            oidcConfigEndpoint = mkOption {
              type = str;
              default = "${cfg.auth.issuerURL}/.well-known/openid-configuration";
              description = "OIDC discovery endpoint.";
            };

            clientId = mkOption {
              type = str;
              default = "";
              description = "OIDC client ID created manually in Zitadel.";
            };

            managementClientId = mkOption {
              type = str;
              default = "netbird";
              description = "Zitadel service user client ID used by NetBird to cache users.";
            };

            managementClientSecretFile = mkOption {
              type = nullOr path;
              default = null;
              description = "Zitadel service user client secret file. If unset, Clan vars prompts for it.";
            };

          };
        };
        default = { };
        description = "NetBird OIDC authentication options.";
      };

      clients = mkOption {
        type = attrsOf (
          submodule (
            { name, config, ... }:
            {
              options = {
                enable = mkEnableOption "NetBird client peer";

                interface = mkOption {
                  type = str;
                  default = "nb-${name}";
                  apply =
                    iface:
                    lib.throwIfNot (
                      builtins.stringLength iface <= 15
                    ) "Network interface name must be 15 characters or less" iface;
                  description = "Local interface managed by this NetBird client.";
                };

                managementURL = mkOption {
                  type = str;
                  default = optionalString cfg.public.enable exposedURL;
                  description = "NetBird management URL.";
                };

                setupKeyFile = mkOption {
                  type = nullOr path;
                  default = null;
                  description = "NetBird setup key file. If unset, Clan vars prompts for it.";
                };

                portOffset = mkOption {
                  type = int;
                  default = 0;
                  description = "Offset added to 20000 + appId for this client's WireGuard port.";
                };

                wireguardPort = mkOption {
                  type = port;
                  default = 20000 + appId + config.portOffset;
                  description = "WireGuard UDP port used by this NetBird client.";
                };

                listenInterfaces = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Interfaces where this client accepts direct NetBird peer traffic.";
                };

                openFirewall = mkEnableOption "Open the client's WireGuard UDP port on listenInterfaces";

                config = mkOption {
                  type = attrs;
                  default = { };
                  description = "Extra NetBird client config merged into services.netbird.clients.<name>.config.";
                };

                environment = mkOption {
                  type = attrsOf str;
                  default = { };
                  description = "Extra NetBird client environment variables.";
                };

                gateway = mkOption {
                  type = submodule {
                    options = {
                      enable = mkEnableOption "NetBird network gateway";

                      networks = mkOption {
                        type = listOf str;
                        default = [ ];
                        description = "CIDR networks routed through this peer in NetBird.";
                      };

                      vlans = mkOption {
                        type = listOf str;
                        default = [ ];
                        description = "VLAN names from homelab.vlans routed through this peer.";
                      };

                      routingFeatures = mkOption {
                        type = enum [
                          "server"
                          "client"
                          "both"
                        ];
                        default = "server";
                        description = "Routing mode required by this gateway.";
                      };
                    };
                  };
                  default = { };
                  description = "Gateway metadata and routing mode for this client.";
                };
              };
            }
          )
        );
        default = { };
        description = "NetBird client peers configured on this host.";
      };
    };
  };

  config = mkMerge [
    {
      homelab.features.${appName}.appInfos = {
        category = appCategory;
        displayName = appDisplayName;
        icon = appIcon;
        platform = appPlatform;
        description = appDescription;
        url = appUrl;
        pinnedVersion = appPinnedVersion;
        serviceURL = exposedURL;
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = length uniquePortOffsets == length enabledClientValues;
          message = "homelab.features.netbird.clients must use unique portOffset values.";
        }
        {
          assertion = !cfg.public.openFirewall || cfg.public.listenInterfaces != [ ];
          message = "homelab.features.netbird.public.listenInterfaces must be set when public.openFirewall is enabled.";
        }
        {
          assertion = !publishesPublicIntegration || cfg.public.enable;
          message = "homelab.features.netbird.public.enable must be enabled to publish homepage, gatus, or victoriametrics integrations.";
        }
        {
          assertion = !publishesRemoteMetrics || cfg.public.metricsAllow != { };
          message = "homelab.features.netbird.public.metricsAllow must be set when publishing remote VictoriaMetrics targets.";
        }
      ]
      ++ (map (interfaceName: {
        assertion = hasAttr interfaceName config.networking.interfaces;
        message = "homelab.features.netbird.public.listenInterfaces references unknown interface '${interfaceName}'.";
      }) cfg.public.listenInterfaces)
      ++ (map (interfaceName: {
        assertion = hasAttr interfaceName config.networking.interfaces;
        message = "homelab.features.netbird.publishIntegrations.victoriametrics.listenInterfaces references unknown interface '${interfaceName}'.";
      }) publishedMetricsListenInterfaces)
      ++ (map (interfaceName: {
        assertion = resolveIntegrationListenAddresses appName [ interfaceName ] != [ ];
        message = "homelab.features.netbird.publishIntegrations.victoriametrics.listenInterfaces interface '${interfaceName}' has no IPv4 address configured.";
      }) publishedMetricsListenInterfaces)
      ++ (mapAttrsToList (clientName: clientCfg: {
        assertion = !clientCfg.openFirewall || clientCfg.listenInterfaces != [ ];
        message = "homelab.features.netbird.clients.${clientName}.listenInterfaces must be set when openFirewall is enabled.";
      }) enabledClients)
      ++ (mapAttrsToList (clientName: clientCfg: {
        assertion = clientCfg.managementURL == "" || parseManagementURL clientCfg.managementURL != null;
        message = "homelab.features.netbird.clients.${clientName}.managementURL must be an http(s) URL without path or query.";
      }) enabledClients)
      ++ (concatLists (
        mapAttrsToList (
          clientName: clientCfg:
          map (interfaceName: {
            assertion = hasAttr interfaceName config.networking.interfaces;
            message = "homelab.features.netbird.clients.${clientName}.listenInterfaces references unknown interface '${interfaceName}'.";
          }) clientCfg.listenInterfaces
        ) enabledClients
      ))
      ++ (concatLists (
        mapAttrsToList (
          clientName: clientCfg:
          map (interfaceName: {
            assertion = hasAttr interfaceName config.networking.interfaces;
            message = "homelab.features.netbird.clients.${clientName}.gateway resolves unknown interface '${interfaceName}'.";
          }) (gatewayInterfaces clientCfg)
        ) enabledClients
      ))
      ++ (concatLists (
        mapAttrsToList (
          clientName: clientCfg:
          (map (vlanName: {
            assertion = hasAttr vlanName config.homelab.vlans;
            message = "homelab.features.netbird.clients.${clientName}.gateway.vlans references unknown VLAN '${vlanName}'.";
          }) clientCfg.gateway.vlans)
          ++ [
            {
              assertion =
                !clientCfg.gateway.enable || clientCfg.gateway.networks != [ ] || clientCfg.gateway.vlans != [ ];
              message = "homelab.features.netbird.clients.${clientName}.gateway must set networks or vlans.";
            }
          ]
        ) enabledClients
      ));

      programs.bash.shellAliases = optionalAttrs cfg.public.enable (
        (mkServiceAliases "netbird-management")
        // {
          "@service-netbird-signal-status" = "systemctl status netbird-signal";
          "@service-netbird-signal-journal" = "journalctl -u netbird-signal";
          "@service-netbird-relay-status" = "systemctl status netbird-relay";
          "@service-netbird-relay-journal" = "journalctl -u netbird-relay";
          "@service-netbird-coturn-status" = "systemctl status coturn";
          "@service-netbird-coturn-journal" = "journalctl -u coturn";
        }
      );

      networking.firewall = mkMerge [
        {
          interfaces = mkMerge ([ publicFirewall ] ++ clientFirewalls);
          extraForwardRules = mkIf (gatewayForwardRules != "") gatewayForwardRules;
        }
        (mkIf (cfg.public.enable && publishMetricsCfg.enable) (mkFirewall metricsFirewallCfg netbirdMetricsPorts))
      ];

      services.netbird = {
        useRoutingFeatures = routingFeatures;
        clients = mapAttrs' mkNetbirdClient enabledClients;
      };

      homelab.integrations.services.${appName} = mkIf publishesAnyIntegration {
        displayName = appDisplayName;
        category = appCategory;
        icon = appIcon;
        description = appDescription;

        homepage = mkIf publishCfg.homepage {
          icon = "sh-${appIcon}";
          href = exposedURL;
          description = "${appDescription} [${cfg.public.serviceDomain}]";
          siteMonitor = monitoringURL;
        };

        gatus = mkIf publishCfg.gatus {
          name = appDisplayName;
          url = monitoringURL;
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          ui.hide-hostname = true;
        };

        victoriametrics = mkIf publishMetricsCfg.enable {
          metrics_path = "/metrics";
          static_configs = [
            (mkPublishedMetricTarget "management" cfg.public.managementMetricsPort)
            (mkPublishedMetricTarget "signal" cfg.public.signalMetricsPort)
            (mkPublishedMetricTarget "relay" cfg.public.relayMetricsPort)
          ];
        };

        grafana = mkIf publishCfg.grafana {
          dashboards = [
            ((mkGrafanaDashboardProvider appName ./grafana/dashboards) // {
              folder = "NetBird";
              folderUid = "netbird";
            })
          ];
        };
      };

      clan.core.vars.generators = listToAttrs (
        concatLists (
          mapAttrsToList mkClientSetupKeyGenerators (
            filterAttrs (_: clientCfg: clientCfg.enable && clientCfg.setupKeyFile == null) cfg.clients
          )
        )
      );
    })

    (mkIf (cfg.enable && cfg.public.enable) {
      homelab.features.${appName} = {
        manualConfiguration = true;
      };

      homelab.domains.localEntries."${appName}-public" = mkIf (cfg.public.registerScope != [ ]) {
        domain = cfg.public.serviceDomain;
        enabled = true;
        host = config.networking.hostName;
        registerScope = cfg.public.registerScope;
        service = appName;
        targetAddress =
          if cfg.public.dnsTargetAddress != null then
            cfg.public.dnsTargetAddress
          else
            config.homelab.host.address;
      };

      clan.core.vars.generators."${appName}-zitadel-service-user" = {
        share = true;
        prompts.client-secret = {
          description = "Please insert the ZITADEL service user ClientSecret for NetBird";
          persist = true;
        };
      };

      clan.core.vars.generators.${appName} = {
        files = {
          coturn-password = {
            owner = "turnserver";
            group = "turnserver";
            mode = "0400";
          };
          data-store-encryption-key = { };
          relay-secret = {
            owner = "netbird-relay";
            group = "netbird-relay";
            mode = "0400";
          };
          turn-secret = { };
          management-client-secret = { };
        };

        runtimeInputs = [ pkgs.openssl ];
        dependencies = [ "${appName}-zitadel-service-user" ];

        script = ''
          openssl rand -base64 32 > "$out/coturn-password"
          openssl rand -base64 32 > "$out/data-store-encryption-key"
          openssl rand -base64 32 > "$out/relay-secret"
          openssl rand -base64 32 > "$out/turn-secret"
          cat "$in/${appName}-zitadel-service-user/client-secret" > "$out/management-client-secret"
        '';
      };

      users.groups.netbird-relay = { };
      users.users.netbird-relay = {
        isSystemUser = true;
        group = "netbird-relay";
      };

      services.coturn = {
        enable = true;
        realm = cfg.public.serviceDomain;
        lt-cred-mech = true;
        no-cli = true;
        no-tls = true;
        no-dtls = true;
        listening-port = cfg.public.turnPort;
        alt-listening-port = cfg.public.turnPort;
        tls-listening-port = cfg.public.turnPort;
        alt-tls-listening-port = cfg.public.turnPort;
        min-port = cfg.public.turnRelayPortRange.from;
        max-port = cfg.public.turnRelayPortRange.to;
        extraConfig = ''
          fingerprint
          user=netbird:@password@
          no-software-attribute
        '';
      };

      systemd.services.coturn.preStart = ''
        ${lib.getExe pkgs.replace-secret} @password@ ${coturnPasswordFile} /run/coturn/turnserver.cfg
      '';

      systemd.services.netbird-relay = {
        description = "NetBird relay server";
        documentation = [ "https://docs.netbird.io/" ];
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          NB_LOG_LEVEL = "info";
          NB_LISTEN_ADDRESS = "127.0.0.1:${toString cfg.public.relayPort}";
          NB_EXPOSED_ADDRESS = "rels://${cfg.public.serviceDomain}:443";
        };

        serviceConfig = {
          ExecStart = relayStart;
          Restart = "always";
          RuntimeDirectory = "netbird-relay";
          StateDirectory = "netbird-relay";
          User = "netbird-relay";
          Group = "netbird-relay";

          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
        };
      };

      services.netbird.server = {
        enable = true;
        domain = cfg.public.serviceDomain;
        enableNginx = false;

        coturn = {
          enable = false;
          domain = cfg.public.serviceDomain;
        };

        management = {
          enable = true;
          enableNginx = false;
          domain = cfg.public.serviceDomain;
          port = cfg.public.managementPort;
          metricsPort = cfg.public.managementMetricsPort;
          extraOptions = cfg.public.management.extraOptions;
          oidcConfigEndpoint = cfg.auth.oidcConfigEndpoint;
          dnsDomain = cfg.dnsDomain;
          turnDomain = cfg.public.serviceDomain;
          turnPort = cfg.public.turnPort;
          settings = recursiveUpdate {
            Stuns = [
              {
                Proto = "udp";
                URI = "stun:${cfg.public.serviceDomain}:${toString cfg.public.turnPort}";
                Username = "";
                Password = null;
              }
            ];
            TURNConfig = {
              Turns = [
                {
                  Proto = "udp";
                  URI = "turn:${cfg.public.serviceDomain}:${toString cfg.public.turnPort}";
                  Username = "netbird";
                  Password._secret = coturnPasswordFile;
                }
              ];
              Secret._secret = config.clan.core.vars.generators.${appName}.files.turn-secret.path;
            };
            Relay = {
              Addresses = [ "rels://${cfg.public.serviceDomain}:443" ];
              CredentialsTTL = "24h";
              Secret._secret = relaySecretFile;
            };
            Signal = {
              Proto = "https";
              URI = "${cfg.public.serviceDomain}:443";
              Username = "";
              Password = null;
            };
            DataStoreEncryptionKey._secret =
              config.clan.core.vars.generators.${appName}.files.data-store-encryption-key.path;
            HttpConfig.OIDCConfigEndpoint = cfg.auth.oidcConfigEndpoint;
            IdpManagerConfig = {
              ManagerType = cfg.auth.provider;
              ClientConfig = {
                Issuer = cfg.auth.issuerURL;
                TokenEndpoint = "${cfg.auth.issuerURL}/oauth/v2/token";
                ClientID = cfg.auth.managementClientId;
                ClientSecret._secret = oidcManagementClientSecretFile;
                GrantType = "client_credentials";
              };
              ExtraConfig = {
                ManagementEndpoint = "${cfg.auth.issuerURL}/management/v1";
              };
              ZitadelClientCredentials = null;
            };
            DeviceAuthorizationFlow = {
              Provider = "hosted";
              ProviderConfig = {
                Audience = cfg.auth.clientId;
                ClientID = cfg.auth.clientId;
                Domain = cfg.auth.issuerURL;
                TokenEndpoint = "${cfg.auth.issuerURL}/oauth/v2/token";
                DeviceAuthEndpoint = "${cfg.auth.issuerURL}/oauth/v2/device_authorization";
                Scope = oidcScopes;
                UseIDToken = false;
              };
            };
            PKCEAuthorizationFlow.ProviderConfig = {
              Audience = cfg.auth.clientId;
              ClientID = cfg.auth.clientId;
              ClientSecret = "";
              AuthorizationEndpoint = "${cfg.auth.issuerURL}/oauth/v2/authorize";
              TokenEndpoint = "${cfg.auth.issuerURL}/oauth/v2/token";
              Scope = oidcScopes;
              RedirectURLs = [
                "http://localhost:53000"
                "${exposedURL}/auth"
                "${exposedURL}/silent-auth"
              ];
              UseIDToken = false;
            };
          } cfg.public.management.settings;
        };

        signal = {
          enable = true;
          enableNginx = false;
          domain = cfg.public.serviceDomain;
          port = cfg.public.signalPort;
          metricsPort = cfg.public.signalMetricsPort;
          extraOptions = cfg.public.signal.extraOptions;
        };

        dashboard = {
          enable = true;
          enableNginx = false;
          domain = cfg.public.serviceDomain;
          managementServer = exposedURL;
          settings = {
            AUTH_AUTHORITY = cfg.auth.issuerURL;
            AUTH_CLIENT_ID = cfg.auth.clientId;
            AUTH_AUDIENCE = cfg.auth.clientId;
            AUTH_SUPPORTED_SCOPES = oidcScopes;
            AUTH_REDIRECT_URI = "/auth";
            AUTH_SILENT_REDIRECT_URI = "/silent-auth";
            USE_AUTH0 = false;
          }
          // cfg.public.dashboard.settings;
        };
      };

      security.acme.acceptTerms = mkIf cfg.public.openFirewall true;

      services.caddy.virtualHosts = mkIf cfg.public.openFirewall {
        "${cfg.public.serviceDomain}" = {
          listenAddresses = resolveListenInterfaceAddresses appName cfg.public.listenInterfaces;
          logFormat = ''
            output file /var/log/caddy/public.log {
              mode 0644
            }
            format json
          '';

          extraConfig = ''
            handle /relay* {
              reverse_proxy ${relayInternalURL}
            }

            handle /ws-proxy/signal* {
              reverse_proxy ${signalWebsocketInternalURL}
            }

            handle /ws-proxy/management* {
              reverse_proxy ${managementInternalURL}
            }

            handle /api* {
              reverse_proxy ${managementInternalURL}
            }

            handle /management.ManagementService/* {
              reverse_proxy h2c://127.0.0.1:${toString cfg.public.managementPort}
            }

            handle /management.ProxyService/* {
              reverse_proxy h2c://127.0.0.1:${toString cfg.public.managementPort}
            }

            handle /signalexchange.SignalExchange/* {
              reverse_proxy ${signalInternalURL}
            }

            handle {
              root * ${config.services.netbird.server.dashboard.finalDrv}
              try_files {path} {path}.html {path}/ /index.html
              file_server
            }
          '';
        };
      };
    })
  ];
}
