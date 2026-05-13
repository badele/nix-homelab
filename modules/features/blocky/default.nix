{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  ...
}:
with lib;
with types;

let
  appName = "blocky";
  appDisplayName = "Blocky";
  appCategory = "Core Services";
  appIcon = "blocky";
  appPlatform = "nixos";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;

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
      enable = mkEnableOption appName;

      settings = mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = import ./settings.nix { inherit config lib appName; };
        description = ''
          ${appDisplayName} configuration. Refer to
          <https://0xerr0r.github.io/blocky/configuration/>
          for details on supported values.
        '';
      };

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      enableMonitoring = mkEnableOption "Enable monitoring features";

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
      openTailscale = mkEnableOption "Open firewall ports for tailscale (incoming)";
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config =
    with lib;
    mkMerge [
      {
        homelab.features.${appName} = {
          appInfos = {
            category = appCategory;
            displayName = appDisplayName;
            icon = appIcon;
            platform = appPlatform;
            description = appDescription;
            url = appUrl;
            pinnedVersion = appPinnedVersion;
            serviceURL = exposedURL;
          };

        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

        homelab.features.${appName} = {
          homepage = mkIf config.services.homepage-dashboard.enable {
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
              "[BODY] == pat(*Version ${appPinnedVersion}*)"
            ];
            ui.hide-hostname = true;
          };

          settings = mkMerge [
            # Default configuration
            (import ./settings.nix)

            # monitoring settings
            (mkIf cfg.enableMonitoring {
              prometheus.enable = true;
            })

            # Serve alias domain
            (mkIf (config.homelab.alias != [ ]) {
              customDNS =
                let
                  aliasMapping = listToAttrs (
                    map (alias: {
                      name = alias;
                      value = config.homelab.host.address;
                    }) config.homelab.alias
                  );
                in
                {
                  customTTL = "1h";
                  filterUnmappedTypes = true;
                  mapping = aliasMapping;
                };
            })

            {
              ports = {
                dns = 53;
                http = listenHttpPort;
              };
            }

          ];
        };

        # Add VictoriaMetrics scrape config if monitoring is enabled
        homelab.features.victoriametrics.scrapeConfigs = lib.mkIf cfg.enableMonitoring [
          {
            job_name = "blocky";
            metrics_path = "/metrics";
            static_configs = [
              {
                targets = [ "http://127.0.0.1:${toString listenHttpPort}" ];
                labels = {
                  instance = config.networking.hostName;
                  hostname = cfg.serviceDomain;
                };
              }
            ];
          }
        ];

        # Add Grafana dashboard if monitoring is enabled
        services.grafana.provision.dashboards.settings.providers = lib.mkIf cfg.enableMonitoring [
          {
            name = "blocky";
            orgId = 1;
            type = "file";
            disableDeletion = true;
            options.path =
              let
                dashboardContent = builtins.readFile ./grafana_dashboard.json;
                # Replace the hardcoded domain with the actual serviceURL
                customizedDashboard =
                  builtins.replaceStrings [ "BLOCKY_URL_CONTENT" ] [ cfg.serviceDomain ]
                    dashboardContent;
              in
              "${pkgs.writeTextDir "${appName}-dashboard.json" customizedDashboard}/${appName}-dashboard.json";
          }
        ];

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [
          53
        ];
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          53
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
          "@service-${appName}-config" =
            "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
        };

        # Enable Blocky service
        services.${appName} = {
          enable = true;
          settings = cfg.settings;
        };

        # Enable blocky in TLS mode with caddy reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
        services.caddy.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            logFormat = ''
              output file /var/log/caddy/public.log {
                mode 0644
              }
              format json
            '';

            extraConfig = ''
              route {
                handle /outpost.goauthentik.io/* {
                  reverse_proxy 127.0.0.1:9000
                }

                forward_auth 127.0.0.1:9000 {
                  uri /outpost.goauthentik.io/auth/caddy
                  copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid
                }

                reverse_proxy 127.0.0.1:${toString listenHttpPort}
              }

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
