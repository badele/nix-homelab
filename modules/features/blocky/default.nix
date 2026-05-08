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

        # Enable blocky in TLS mode with nginx reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
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
                ##############################
                # authentik-specific config
                ##############################
                auth_request     /outpost.goauthentik.io/auth/nginx;
                error_page       401 = @goauthentik_proxy_signin;
                auth_request_set $auth_cookie $upstream_http_set_cookie;
                add_header       Set-Cookie $auth_cookie;

                # translate headers from the outposts back to the actual upstream
                auth_request_set $authentik_username $upstream_http_x_authentik_username;
                auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
                auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
                auth_request_set $authentik_email $upstream_http_x_authentik_email;
                auth_request_set $authentik_name $upstream_http_x_authentik_name;
                auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

                proxy_set_header X-authentik-username $authentik_username;
                proxy_set_header X-authentik-groups $authentik_groups;
                proxy_set_header X-authentik-entitlements $authentik_entitlements;
                proxy_set_header X-authentik-email $authentik_email;
                proxy_set_header X-authentik-name $authentik_name;
                proxy_set_header X-authentik-uid $authentik_uid;

                ##############################
                # Service Security Headers
                ##############################
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

            # all requests to /outpost.goauthentik.io must be accessible without authentication
            locations."/outpost.goauthentik.io" = {
              proxyPass = "http://127.0.0.1:9000/outpost.goauthentik.io";
              extraConfig = ''
                proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
                add_header              Set-Cookie $auth_cookie;
                auth_request_set        $auth_cookie $upstream_http_set_cookie;
                proxy_pass_request_body off;
                proxy_set_header        Content-Length "";
              '';
            };

            # Special location for when the /auth endpoint returns a 401,
            # redirect to the /start URL which initiates SSO
            locations."@goauthentik_proxy_signin" = {
              extraConfig = ''
                internal;
                add_header Set-Cookie $auth_cookie;
                return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
                # For domain level, use the below error_page to redirect to your authentik server with the full redirect path
                # return 302 https://authentik.company/outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
              '';
            };

            extraConfig = ''
              # Buffer sizes pour Authentik (IMPORTANT)
              proxy_buffers 8 16k;
              proxy_buffer_size 32k;

              access_log /var/log/nginx/public.log vcombined;
            '';
          };
        };
      })
    ];
}
