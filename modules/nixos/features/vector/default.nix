{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  appName = "vector";
  appCategory = "System Health";
  appDisplayName = "Vector";
  appPlatform = "nixos";
  appIcon = "sh-vector";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;
  appNixpkgsVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  victorialogsPort = 10000 + config.homelab.portRegistry.victorialogs.appId;
  cefListenAddresses = resolveListenInterfaceAddresses appName cfg.cef.listenInterfaces;

  cefRules = import ./rules/cef.nix {
    inherit cfg;
    listenAddresses = cefListenAddresses;
  };

  cefMikrotikFirewallRules = import ./rules/cef_mikrotik_firewall.nix {
    inputName = "cef_cleaned";
  };

  cefMikrotikFirewallOutput =
    if cfg.cef.mikrotikFirewall.enable then "cef_mikrotik_firewall_enriched" else "cef_cleaned";

  cefMikrotikLoginRules = import ./rules/cef_mikrotik_login.nix {
    inputName = cefMikrotikFirewallOutput;
  };

  cefOutput =
    if cfg.cef.mikrotikLogin.enable then "cef_mikrotik_login_enriched" else cefMikrotikFirewallOutput;

  victorialogsSinkInputs = optionals cfg.cef.enable [ cefOutput ];

  victorialogsRules = import ./rules/victorialogs.nix {
    inherit cfg;
    sinkInputs = victorialogsSinkInputs;
  };

  enabledRuleSets =
    optionals cfg.cef.enable [ cefRules ]
    ++ optionals (cfg.cef.enable && cfg.cef.mikrotikFirewall.enable) [ cefMikrotikFirewallRules ]
    ++ optionals (cfg.cef.enable && cfg.cef.mikrotikLogin.enable) [ cefMikrotikLoginRules ]
    ++ optionals cfg.victorialogs.enable [ victorialogsRules ];

  mergeRuleAttr =
    attrName: foldl' recursiveUpdate { } (map (ruleSet: ruleSet.${attrName} or { }) enabledRuleSets);

  cefFirewallInterfaces = listToAttrs (
    map (interfaceName: {
      name = interfaceName;
      value = {
        allowedUDPPorts = [ cfg.cef.port ];
      };
    }) cfg.cef.listenInterfaces
  );
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      journaldAccess = mkOption {
        type = bool;
        default = false;
        description = "Allow Vector to read journald.";
      };

      dataDir = mkOption {
        type = str;
        default = "/var/lib/vector";
        description = "Vector data directory.";
      };

      cef = {
        enable = mkEnableOption "CEF ingestion";

        port = mkOption {
          type = port;
          default = 5515;
          description = "UDP port used by the CEF source.";
        };

        listenInterfaces = mkOption {
          type = listOf str;
          default = [ ];
          description = "Network interfaces accepting incoming CEF events.";
        };

        mikrotikFirewall.enable = mkEnableOption "MikroTik firewall CEF enrichment";

        mikrotikLogin.enable = mkEnableOption "MikroTik login CEF enrichment";
      };

      victorialogs = {
        enable = mkEnableOption "Forward Vector events to VictoriaLogs";

        endpoint = mkOption {
          type = str;
          default = "http://127.0.0.1:${toString victorialogsPort}/insert/elasticsearch/";
          description = "VictoriaLogs Elasticsearch bulk endpoint.";
        };
      };
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
    {
      homelab.features.${appName} = {
        appInfos = {
          category = appCategory;
          displayName = appDisplayName;
          platform = appPlatform;
          icon = appIcon;
          description = appDescription;
          url = appUrl;
          pinnedVersion = appPinnedVersion;
          nixpkgsVersion = appNixpkgsVersion;
        };
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.cef.enable || cfg.cef.listenInterfaces != [ ];
          message = "homelab.features.${appName}.cef.listenInterfaces must be set when cef.enable is true.";
        }
        {
          assertion = !cfg.victorialogs.enable || victorialogsSinkInputs != [ ];
          message = "homelab.features.${appName}.victorialogs.enable requires at least one enabled Vector log source.";
        }
      ];

      networking.firewall.interfaces = optionalAttrs cfg.cef.enable cefFirewallInterfaces;

      programs.bash.shellAliases = (mkServiceAliases appName) // {
        "@service-${appName}-config" =
          "vector validate --config-yaml $(systemctl cat ${appName} | grep -oP '(?<=--config-yaml )\\S+')";
      };

      services.vector = {
        enable = true;
        journaldAccess = cfg.journaldAccess;

        settings = {
          data_dir = cfg.dataDir;
          sources = mergeRuleAttr "sources";
          transforms = mergeRuleAttr "transforms";
          sinks = mergeRuleAttr "sinks";
        };
      };
    })
  ];
}
