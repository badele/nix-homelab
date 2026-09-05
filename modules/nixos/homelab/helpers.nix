{ lib }:
with lib;
with types;
let
  inherit (lib) mkOption types;

  appInfosOptions = {
    category = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Application category (e.g., "Network & Administration", "Media", etc.)
      '';
    };

    displayName = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Human-readable application name
      '';
    };

    description = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Application description
      '';
    };

    icon = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        URL to application icon
      '';
    };

    url = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        URL to application homepage or documentation
      '';
    };

    image = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Container image name
      '';
    };

    pinnedVersion = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        Application/container version
      '';
    };

    nixpkgsVersion = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        last Application/container version
      '';
    };

    platform = mkOption {
      type = enum [
        "nixos"
        "podman"
      ];
      default = "podman";
      description = ''
        Deployment platform for this application:
        - "nixos": Deploy as a native NixOS service
        - "podman": Deploy as a Podman container
      '';
    };

    public = mkEnableOption "Is this application publicly accessible?";

    serviceURL = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        URL to access the application/service
      '';
    };

    deprecated = mkOption {
      type = str;
      default = "";
      description = ''
        An message for the reason this feature is deprecated
      '';
    };
  };

  publishIntegrationsOptions = {
    homepage = mkEnableOption "Publish the Homepage integration";

    gatus = mkEnableOption "Publish the Gatus integration";

    grafana = mkEnableOption "Publish the Grafana integration";

    vmalert = mkEnableOption "Publish the VMAlert integration";

    victoriametrics = mkOption {
      type = submodule {
        options = {
          enable = mkEnableOption "Publish the VictoriaMetrics integration";

          listenInterfaces = mkOption {
            type = listOf str;
            default = [ "lo" ];
            description = ''
              Network interfaces used to publish VictoriaMetrics scrape targets.
              Use "lo" to publish localhost targets.
            '';
          };
        };
      };
      default = { };
      description = "VictoriaMetrics integration publication settings.";
    };
  };

  # Helper function to create common feature options
  # Usage in feature modules: mkFeatureOptions { extraOptions = { ... }; }
  mkFeatureOptions =
    { extraOptions ? { }
    ,
    }:
    {
      enable = mkEnableOption "Enable this feature";
      manualConfiguration = mkEnableOption ''
        This feature requires manual configuration, 
         ex: init account, add new OIDC application (authentik)
      '';

      appInfos = mkOption {
        type = submodule { options = appInfosOptions; };
        default = { };
        description = ''
          Application informations
        '';
      };

      publishIntegrations = mkOption {
        type = submodule { options = publishIntegrationsOptions; };
        default = { };
        description = ''
          Explicit service integrations published by this feature.
        '';
      };

      collectIntegrations = mkOption {
        type = attrsOf (listOf str);
        default = { };
        description = ''
          Shared service integrations collected by this feature, keyed by machine.
        '';
      };

      homepage = mkOption {
        type = nullOr attrs;
        default = null;
        description = ''
          Homepage dashboard configuration for this service.
          If set, this service will appear in the homepage dashboard.
        '';
      };

      gatus = mkOption {
        type = nullOr attrs;
        default = null;
        description = ''
          gatus configuration for this service.
          If set, this service will appear in the gatus dashboard.
        '';
      };

      listenInterfaces = mkOption {
        type = listOf str;
        default = [ ];
        description = ''
          Network interfaces used to expose this feature.
          Interface names are resolved to IPv4 addresses from networking.interfaces.
        '';
      };

      registerScope = mkOption {
        type = listOf str;
        default = [ ];
        description = ''
          DNS registration scopes used when publishing this feature domain.
        '';
      };

      dnsTargetAddress = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          Explicit IPv4 address published for this feature domain.
        '';
      };

      remoteAccess = mkEnableOption "Allow remote access to this application (create new listening port 20000 + appId";

      allow = mkOption {
        type = attrsOf str;
        default = { };
        description = ''
          Remote machines allowed to reach this feature, keyed by machine name.
          Values are shared host address selectors such as management, infra,
          public, or an interface name.
        '';
      };

    }
    // extraOptions;

  # Helper function to create Podman container management aliases
  mkPodmanAliases = appName: {
    "@service-${appName}-config" = "cat $(podman inspect ${appName} | jq -r .[0].Mounts[0].Source)";
    "@service-${appName}-journal" = "journalctl -u podman-${appName}";
    "@service-${appName}-podman-config" =
      "cat $(systemctl cat podman-${appName} | grep ExecStart= | cut -d= -f2)";
    "@service-${appName}-shell" = "podman exec -it ${appName} bash";
    "@service-${appName}-start" = "systemctl start podman-${appName}";
    "@service-${appName}-stop" = "systemctl stop podman-${appName}";
    "@service-${appName}-restart" = "systemctl restart podman-${appName}";
    "@service-${appName}-status" = "systemctl status podman-${appName}";
  };

  mkServiceAliases = appName: {
    "@service-${appName}-journal" = "journalctl -u ${appName}";
    "@service-${appName}-start" = "systemctl start ${appName}";
    "@service-${appName}-stop" = "systemctl stop ${appName}";
    "@service-${appName}-restart" = "systemctl restart ${appName}";
    "@service-${appName}-status" = "systemctl status ${appName}";
  };

  mkGrafanaDashboardProvider = appName: path: {
    name = appName;
    orgId = 1;
    type = "file";
    disableDeletion = true;
    options.path = path;
  };

  mkFirewallInterfaces =
    cfg: ports:
    mkIf cfg.openFirewall (
      genAttrs cfg.listenInterfaces (_: {
        allowedTCPPorts = ports;
      })
    );

in
{
  inherit
    mkFeatureOptions
    mkPodmanAliases
    mkServiceAliases
    mkGrafanaDashboardProvider
    mkFirewallInterfaces
    ;
}
