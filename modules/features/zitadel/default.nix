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
  appName = "zitadel";
  appDisplayName = "ZITADEL";
  appCategory = "Core Services";
  appIcon = "zitadel";
  appPlatform = "nixos";

  cfg = config.homelab.features.${appName};

  appDescription = "Identity and access management platform";
  appUrl = "https://github.com/zitadel/zitadel";
  appPinnedVersion = "2.71.7";

  listenZitadelPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenZitadelPort}";
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
        default = {
          Port = listenZitadelPort;
          ExternalSecure = true;
          ExternalPort = 443;
        };
        # Database.postgres = {
        #   Host = "localhost";
        #   Port = 5432;
        #   Database = "zitadel";
        #   User.Username = "zitadel";
        #   Admin.Username = "postgres";
        # };
        description = ''
          ${appDisplayName} runtime configuration. Refer to
          <https://zitadel.com/docs/self-hosting/manage/configure>
          for details on supported values.
        '';
      };

      steps = mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          ${appDisplayName} database initialization configuration (FirstInstance setup).
          See <https://zitadel.com/docs/self-hosting/manage/configure> for details.
        '';
      };

      tlsMode = mkOption {
        type = lib.types.enum [
          "external"
          "enabled"
          "disabled"
        ];
        default = "external";
        description = ''
          TLS mode for ${appDisplayName}:
          - external: ZITADEL forces HTTPS, TLS terminated at nginx reverse proxy (recommended).
          - enabled: ZITADEL handles TLS directly.
          - disabled: HTTP only (testing only).
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
            siteMonitor = "${internalURL}/debug/healthz";
          };

          gatus = mkIf config.services.gatus.enable {
            name = appDisplayName;
            url = "${internalURL}/debug/healthz";
            group = appCategory;
            type = "HTTP";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
            ];
            ui.hide-hostname = true;
          };
        };

        #######################################################################
        # Service
        #######################################################################
        users.users.zitadel = {
          isSystemUser = true;
          group = "zitadel";
          home = "/var/lib/zitadel";
          createHome = true;
        };
        users.groups.zitadel = { };

        clan.core.vars.generators.${appName} = {
          files = {
            adminAccount = {
              secret = false;
            };

            masterkey = {
              owner = "zitadel";
              group = "zitadel";
            };
          };

          runtimeInputs = [
            pkgs.openssl
          ];

          script = ''
            # Generate 32-byte master key for ZITADEL encryption
            openssl rand 32 | head -c 32 > "$out/masterkey"

            echo "zitadel-admin" > "$out/adminAccount"
          '';
        };

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
          "@service-${appName}-status" = "systemctl status zitadel";
        };

        # Enable ZITADEL service
        services.zitadel = {
          enable = true;
          masterKeyFile = config.clan.core.vars.generators.${appName}.files.masterkey.path;
          tlsMode = cfg.tlsMode;
          settings = {
            Port = listenZitadelPort;
            ExternalDomain = cfg.serviceDomain;
            ExternalPort = 443;
            ExternalSecure = true;
          }
          // cfg.settings;
          steps = {
            FirstInstance = {
              InstanceName = "Homelab";
              Org = {
                Name = "Homelab";
                Human = {
                  UserName = "zitadel-admin";
                  FirstName = "Admin";
                  LastName = "Homelab";
                };
              };
            };
          }
          // cfg.steps;
        };

        # Enable ZITADEL in TLS mode with nginx reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            # Use wildcard domain
            useACMEHost = config.homelab.domain;
            forceSSL = true;

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString listenZitadelPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;

              # Security headers
              extraConfig = ''
                # Required for gRPC and HTTP/2 support
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

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
                add_header Content-Security-Policy "default-src 'self'; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https: wss:;" always;

                # Modern CORS headers
                add_header Cross-Origin-Opener-Policy "same-origin-allow-popups" always;
                add_header Cross-Origin-Resource-Policy "cross-origin" always;
                add_header Cross-Origin-Embedder-Policy "unsafe-none" always;

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
