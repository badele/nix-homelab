{
  config,
  inputs,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
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
  appPinnedVersion = inputs.nixpkgs-victoriametrics.legacyPackages.${pkgs.system}.${appName}.version;
  appNixpkgsVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  prometheusConfig = {
    scrape_configs = cfg.scrapeConfigs;
  };

  # Get port from central registry
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

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        443
      ];

      services.grafana.provision.datasources.settings = {
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
            access = "proxy";
            url = "https://${config.homelab.features.victoriametrics.serviceDomain}";
            version = 1;
            editable = true;
            isDefault = false;
          }
        ];
      };

      services.victoriametrics = {
        enable = true;
        package = inputs.nixpkgs-victoriametrics.legacyPackages.${pkgs.system}.victoriametrics;

        # webui and prometheus remote write endpoint
        listenAddress = "127.0.0.1:${toString listenHttpPort}";

        retentionPeriod = "100y";

        extraOptions = [
          "-selfScrapeInterval=5s"
        ];

      };

      services.vmagent = {
        enable = true;
        package = inputs.nixpkgs-victoriametrics.legacyPackages.${pkgs.system}.vmagent;

        remoteWrite.url = "${cfg.agentRewriteUrl}";

        prometheusConfig = prometheusConfig;
      };

      homelab.alias = [ "${cfg.serviceDomain}" ];

      services.nginx.virtualHosts = lib.mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          # Use wildcard domain
          useACMEHost = config.homelab.domain;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString listenHttpPort}";
            recommendedProxySettings = true;
            proxyWebsockets = true;

            # Security headers
            extraConfig = ''
              # Force HTTPS (for 1 year)
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

              # XSS and clickjacking protection
              add_header X-Frame-Options "SAMEORIGIN" always;

              # No execution of untrusted MIME types
              add_header X-Content-Type-Options "nosniff" always;

              # Send only domain with URL referer
              add_header Referrer-Policy "strict-origin-when-cross-origin" always;

              # Disable all unused browser features for better privacy
              add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

              # Allow only specific sources to load content (CSP)
              add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;

              # Modern CORS headers
              add_header Cross-Origin-Opener-Policy "same-origin" always;
              add_header Cross-Origin-Resource-Policy "same-origin" always;
              add_header Cross-Origin-Embedder-Policy "require-corp" always;

              # Cross-domain policy
              add_header X-Permitted-Cross-Domain-Policies "none" always;
            '';
          };

          extraConfig = ''
            access_log /var/log/nginx/public.log vcombined;
          '';
        };
      };
    })
  ];
}
