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

  # Create a rootless podman service running under a dedicated system user "pod-<name>".
  # The user is invisible in GDM (isSystemUser), has its own UID namespace, and is
  # fully isolated from other services. Root can still manage it via machinectl.
  # pkgs must be passed explicitly by the calling module.
  mkRootlessPodmanService =
    {
      pkgs,
      name,
      image,
      subUidStart,
      volumes ? [ ],
      ports ? [ ],
      environment ? { },
      environmentFiles ? [ ],
      credentials ? [ ],
      preStartChown ? [ ],
      extraOptions ? [ ],
      extraServiceConfig ? { },
    }:
    let
      username = "pod-${name}";
      homeDir = "/var/lib/pod-containers/${username}";
      runtimeDir = "/run/${username}";

      startScript = pkgs.writeShellScript "pod-${name}-start" ''
        exec ${pkgs.podman}/bin/podman run --rm \
          --name=${name} \
          ${lib.concatStringsSep " \\\n          " (
            map (v: "--volume=${lib.escapeShellArg v}") volumes
            ++ map (p: "--publish=${lib.escapeShellArg p}") ports
            ++ map (kv: "--env=${lib.escapeShellArg "${kv.name}=${kv.value}"}") (lib.attrsToList environment)
            ++ map (e: "--env-file=${lib.escapeShellArg e}") environmentFiles
            ++ map (c: "--env-file=\"$CREDENTIALS_DIRECTORY/${c.id}\"") credentials
            ++ [ "--cgroup-manager=cgroupfs" ]
            ++ extraOptions
            ++ [ image ]
          )}
      '';
    in
    {
      users.users.${username} = {
        isSystemUser = true;
        group = username;
        home = homeDir;
        createHome = false;
        shell = "${pkgs.bash}/bin/bash";
        subUidRanges = [ { startUid = subUidStart; count = 65536; } ];
        subGidRanges = [ { startGid = subUidStart; count = 65536; } ];
      };
      users.groups.${username} = { };

      systemd.tmpfiles.rules = [
        "d /var/lib/pod-containers 0755 root root -"
        "d ${homeDir} 0750 ${username} ${username} -"
        "d ${runtimeDir} 0700 ${username} ${username} -"
      ];

      systemd.services."pod-${name}" = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        environment = {
          HOME = homeDir;
          XDG_RUNTIME_DIR = runtimeDir;
          PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
        };
        serviceConfig = {
          User = username;
          Group = username;
          LoadCredential = map (c: "${c.id}:${c.path}") credentials;
          ExecStartPre = map (p: "+${pkgs.coreutils}/bin/chown -R ${username}:${username} ${p}") preStartChown;
          ExecStart = "${startScript}";
          ExecStop = "${pkgs.podman}/bin/podman stop ${name}";
          ExecStopPost = "${pkgs.podman}/bin/podman rm -f ${name}";
          Restart = "always";
          RestartSec = "5s";
        } // extraServiceConfig;
      };
    };

  mkRootlessPodmanAliases = appName: {
    "@service-${appName}-journal" = "journalctl -u pod-${appName}";
    "@service-${appName}-start" = "systemctl start pod-${appName}";
    "@service-${appName}-stop" = "systemctl stop pod-${appName}";
    "@service-${appName}-restart" = "systemctl restart pod-${appName}";
    "@service-${appName}-status" = "systemctl status pod-${appName}";
    "@service-${appName}-shell" = "sudo -H -u pod-${appName} bash -c 'export XDG_RUNTIME_DIR=/run/pod-${appName}; cd /var/lib/pod-containers/pod-${appName}; exec bash'";
    "@service-${appName}-pod-shell" = "sudo -H -u pod-${appName} bash -c 'cd /var/lib/pod-containers/pod-${appName} && XDG_RUNTIME_DIR=/run/pod-${appName} podman --cgroup-manager=cgroupfs exec -it ${appName} bash'";
    "@service-${appName}-ps" = "sudo -H -u pod-${appName} bash -c 'cd /var/lib/pod-containers/pod-${appName} && XDG_RUNTIME_DIR=/run/pod-${appName} podman --cgroup-manager=cgroupfs ps'";
  };

in
{
  inherit
    mkFeatureOptions
    mkPodmanAliases
    mkServiceAliases
    mkGrafanaDashboardProvider
    mkFirewallInterfaces
    mkRootlessPodmanService
    mkRootlessPodmanAliases
    ;
}
