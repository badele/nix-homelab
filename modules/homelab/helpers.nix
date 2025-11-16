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
  };

  # Helper function to create common feature options
  # Usage in feature modules: mkFeatureOptions { extraOptions = { ... }; }
  mkFeatureOptions =
    {
      extraOptions ? { },
    }:
    {
      enable = mkEnableOption "Enable this feature";

      appInfos = mkOption {
        type = submodule { options = appInfosOptions; };
        default = { };
        description = ''
          Application informations
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

      remoteAccess = mkEnableOption "Allow remote access to this application (create new listening port 20000 + appId";

    }
    // extraOptions;

  # Helper function to create Podman container management aliases
  mkPodmanAliases = appName: {
    "@service-${appName}-config" = "cat $(podman inspect ${appName} | jq -r .[0].Mounts[0].Source)";
    "@service-${appName}-logs" = "journalctl -u podman-${appName}";
    "@service-${appName}-podman-config" =
      "cat $(systemctl cat podman-${appName} | grep ExecStart= | cut -d= -f2)";
    "@service-${appName}-shell" = "podman exec -it ${appName} bash";
    "@service-${appName}-start" = "systemctl start podman-${appName}";
    "@service-${appName}-stop" = "systemctl stop podman-${appName}";
    "@service-${appName}-restart" = "systemctl restart podman-${appName}";
    "@service-${appName}-status" = "systemctl status podman-${appName}";
  };

  mkServiceAliases = appName: {
    "@service-${appName}-logs" = "journalctl -u ${appName}";
    "@service-${appName}-start" = "systemctl start ${appName}";
    "@service-${appName}-stop" = "systemctl stop ${appName}";
    "@service-${appName}-restart" = "systemctl restart ${appName}";
    "@service-${appName}-status" = "systemctl status ${appName}";
  };

in
{
  inherit mkFeatureOptions mkPodmanAliases mkServiceAliases;
}
