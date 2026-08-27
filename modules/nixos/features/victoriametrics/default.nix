{ config
, inputs
, lib
, pkgs
, mkFeatureOptions
, mkGrafanaDashboardProvider
, mkServiceAliases
, resolveListenInterfaceAddresses
, ...
}:
with lib;
with types;

let
  appName = "victoriametrics";
  appCategory = "System Health";
  appDisplayName = "Victoriametrics";
  appPlatform = "nixos";
  appIcon = "victoriametrics";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion =
    inputs.nixpkgs-victoriametrics.legacyPackages.${pkgs.stdenv.hostPlatform.system}.${appName}.version;
  appNixpkgsVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  prometheusConfig = {
    scrape_configs = cfg.scrapeConfigs ++ integrationScrapeConfigs;
  };

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;
  vmagentHttpPort = listenHttpPort + 1;
  vmalertHttpPort = listenHttpPort + 2;
  alertmanagerHttpPort = listenHttpPort + 3;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";
  localURL = "http://127.0.0.1:${toString listenHttpPort}";
  vmalertLocalURL = "http://127.0.0.1:${toString vmalertHttpPort}";
  alertmanagerLocalURL = "http://127.0.0.1:${toString alertmanagerHttpPort}";

  integrationServicesWithScrapes = lib.filterAttrs
    (
      _: service: service.victoriametrics != null
    )
    config.homelab.integrations.services;

  integrationScrapeConfigs = lib.mapAttrsToList
    (
      serviceName: service:
        {
          job_name = serviceName;
        }
        // service.victoriametrics
    )
    integrationServicesWithScrapes;

  integrationServicesWithVmalertRules = lib.filterAttrs
    (
      _: service: service.vmalert != null
    )
    config.homelab.integrations.services;

  integrationVmalertRuleGroups = lib.flatten (
    lib.mapAttrsToList (_: service: service.vmalert.ruleGroups or [ ]) integrationServicesWithVmalertRules
  );

  vmalertEnabled = integrationVmalertRuleGroups != [ ];

in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      agentRewriteUrl = mkOption {
        type = str;
        default = "https://${cfg.serviceDomain}/api/v1/write";
        description = "victoriametrics URL for pushing metrics";
      };

      scrapeConfigs = mkOption {
        type = listOf attrs;
        default = [ ];
        description = ''
          Additional Prometheus scrape configurations for the agent.
          See: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config

          example:
            [
              {
                job_name = "telegraf-exporter";
                metrics_path = "/metrics";
                static_configs = [
                  {
                    targets = [ "127.0.0.1:9273" ];
                    labels.type = "telegraf";
                  }
                ];
              }
            ]
        '';
      };

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
  config = lib.mkMerge [
    # Always set appInfos, even when disabled
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

    # Only apply when enabled
    (lib.mkIf cfg.enable {

      homelab.features.${appName} = {
        homepage = {
          icon = appIcon;
          href = exposedURL;
          description = "${appDescription}  [${cfg.serviceDomain}]";
          siteMonitor = internalURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = internalURL;
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY] == pat(*Single-node VictoriaMetrics*)"
          ];
          ui.hide-hostname = true;
        };
      };

      homelab.integrations.services.${appName} = mkDefault {
        displayName = appDisplayName;
        category = appCategory;
        icon = appIcon;
        description = appDescription;
        grafana = {
          plugins = [
            pkgs.grafanaPlugins.victoriametrics-metrics-datasource
          ];
          deleteDatasources = [
            {
              name = "Prometheus";
              orgId = 1;
            }
            {
              name = "MikroTik Alerting";
              orgId = 1;
            }
          ];
          datasources = [
            {
              name = "VictoriaMetrics";
              type = "victoriametrics-metrics-datasource";
              access = "proxy";
              url = "https://${config.homelab.features.victoriametrics.serviceDomain}";
              version = 1;
              editable = true;
              isDefault = true;
              jsonData = {
                httpMethod = "POST";
                timeInterval = "30s";
              };
            }
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "homelab-prometheus";
              access = "proxy";
              url = "https://${config.homelab.features.victoriametrics.serviceDomain}";
              version = 1;
              editable = true;
              isDefault = false;
            }
            {
              name = "Alertmanager";
              type = "alertmanager";
              uid = "homelab-alertmanager";
              access = "proxy";
              url = alertmanagerLocalURL;
              version = 1;
              editable = true;
              jsonData = {
                implementation = "prometheus";
              };
            }
          ];
          dashboards = [
            (mkGrafanaDashboardProvider appName ./grafana/dashboards)
          ];
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        443
      ];

      services.victoriametrics = {
        enable = true;
        package = pkgs.victoriametrics;

        # webui and prometheus remote write endpoint
        listenAddress = "127.0.0.1:${toString listenHttpPort}";

        retentionPeriod = "100y";

        extraOptions = [
          "-selfScrapeInterval=5s"
        ] ++ lib.optional vmalertEnabled "-vmalert.proxyURL=${vmalertLocalURL}";

      };

      services.vmagent = {
        enable = true;
        package = pkgs.vmagent;

        remoteWrite.url = "${cfg.agentRewriteUrl}";

        prometheusConfig = prometheusConfig;

        extraArgs = [
          "-httpListenAddr=127.0.0.1:${toString vmagentHttpPort}"
        ];
      };

      services.vmalert.instances.homelab = lib.mkIf vmalertEnabled {
        enable = true;
        rules = {
          groups = integrationVmalertRuleGroups;
        };
        settings = {
          "datasource.url" = localURL;
          "remoteRead.url" = localURL;
          "remoteWrite.url" = "${localURL}/api/v1/write";
          "notifier.url" = [ alertmanagerLocalURL ];
          httpListenAddr = "127.0.0.1:${toString vmalertHttpPort}";
          evaluationInterval = "1m";
        };
      };

      services.prometheus.alertmanager = lib.mkIf vmalertEnabled {
        enable = true;
        listenAddress = "127.0.0.1";
        port = alertmanagerHttpPort;
        configuration = {
          route = {
            receiver = "log";
            group_by = [
              "alertname"
              "service"
              "router"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
          };
          receivers = [
            {
              name = "log";
            }
          ];
        };
      };

      homelab.alias = [ "${cfg.serviceDomain}" ];

      programs.bash.shellAliases = (mkServiceAliases appName) // {
        "@service-${appName}-config" = "systemctl cat ${appName}";
        "@service-${appName}-agent-journal" = "journalctl -u vmagent";
        "@service-${appName}-agent-start" = "systemctl start vmagent";
        "@service-${appName}-agent-stop" = "systemctl stop vmagent";
        "@service-${appName}-agent-restart" = "systemctl restart vmagent";
        "@service-${appName}-agent-status" = "systemctl status vmagent";
        "@service-${appName}-agent-config" = "systemctl cat vmagent";
        "@service-${appName}-alert-journal" = "journalctl -u vmalert-homelab";
        "@service-${appName}-alert-start" = "systemctl start vmalert-homelab";
        "@service-${appName}-alert-stop" = "systemctl stop vmalert-homelab";
        "@service-${appName}-alert-restart" = "systemctl restart vmalert-homelab";
        "@service-${appName}-alert-status" = "systemctl status vmalert-homelab";
        "@service-${appName}-alert-config" = "systemctl cat vmalert-homelab";
        "@service-${appName}-alertmanager-journal" = "journalctl -u alertmanager";
        "@service-${appName}-alertmanager-status" = "systemctl status alertmanager";
      };

      services.caddy.virtualHosts = lib.mkIf cfg.openFirewall {
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
