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
  appName = "victorialogs";
  appCategory = "System Health";
  appDisplayName = "VictoriaLogs";
  appPlatform = "nixos";
  appIcon = "victoriametrics";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;
  appNixpkgsVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
      openTailscale = mkEnableOption "Open firewall ports for tailscale (incoming)";
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
          serviceURL = exposedURL;
        };
      };
    }

    (mkIf cfg.enable {
      homelab.features.${appName} = {
        homepage = {
          icon = appIcon;
          href = exposedURL;
          description = "${appDescription} [${cfg.serviceDomain}]";
          siteMonitor = "${internalURL}/ping";
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = "${internalURL}/ping";
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
          ];
          ui.hide-hostname = true;
        };
      };

      homelab.integrations.services.${appName} = mkDefault {
        displayName = appDisplayName;
        category = appCategory;
        icon = appIcon;
        description = appDescription;
        victoriametrics = {
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString listenHttpPort}" ];
              labels = {
                instance = config.networking.hostName;
                service = appName;
              };
            }
          ];
        };
        grafana = {
          plugins = [
            pkgs.grafanaPlugins.victoriametrics-logs-datasource
          ];
          datasources = [
            {
              name = "VictoriaLogs";
              type = "victoriametrics-logs-datasource";
              access = "proxy";
              url = exposedURL;
              version = 1;
              editable = true;
              isDefault = false;
              jsonData = {
                maxLines = 1000;
                timeInterval = "30s";
              };
            }
          ];
          dashboards = [
            {
              name = appName;
              orgId = 1;
              type = "file";
              disableDeletion = true;
              options.path = "${pkgs.writeTextDir "${appName}-dashboard.json" (builtins.readFile ./grafana_dashboard.json)}/${appName}-dashboard.json";
            }
          ];
        };
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        443
      ];

      services.victorialogs = {
        enable = true;
        package = pkgs.victorialogs;
        listenAddress = "127.0.0.1:${toString listenHttpPort}";
      };

      homelab.alias = [ cfg.serviceDomain ];

      programs.bash.shellAliases =
        (mkServiceAliases appName)
        // {
          "@service-${appName}-config" = "systemctl cat ${appName}";
        }
        // optionalAttrs (config.homelab.features.vector.victorialogs.enable or false) {
          "@service-${appName}-agent-journal" = "journalctl -u vector";
          "@service-${appName}-agent-start" = "systemctl start vector";
          "@service-${appName}-agent-stop" = "systemctl stop vector";
          "@service-${appName}-agent-restart" = "systemctl restart vector";
          "@service-${appName}-agent-status" = "systemctl status vector";
          "@service-${appName}-agent-config" = "systemctl cat vector";
        };

      services.caddy.virtualHosts = mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          listenAddresses = resolveListenInterfaceAddresses appName cfg.listenInterfaces;
          logFormat = ''
            output file /var/log/caddy/public.log {
              mode 0644
            }
            format json
          '';

          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString listenHttpPort}

            header {
              # Force HTTPS for one year.
              Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

              # XSS and clickjacking protection.
              X-Frame-Options "SAMEORIGIN"

              # Prevent execution of untrusted MIME types.
              X-Content-Type-Options "nosniff"

              # Send only the origin as referrer for cross-origin requests.
              Referrer-Policy "strict-origin-when-cross-origin"

              # Disable unused browser features for better privacy.
              Permissions-Policy "geolocation=(), microphone=(), camera=()"

              # Allow only specific sources to load content.
              Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;"

              # Modern cross-origin isolation headers.
              Cross-Origin-Opener-Policy "same-origin"
              Cross-Origin-Resource-Policy "same-origin"
              Cross-Origin-Embedder-Policy "require-corp"

              # Cross-domain policy.
              X-Permitted-Cross-Domain-Policies "none"
            }
          '';
        };
      };
    })
  ];
}
