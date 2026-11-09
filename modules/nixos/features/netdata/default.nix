{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkFirewall,
  mkServiceAliases,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;
let
  appName = "netdata";
  appCategory = "System Health";
  appDisplayName = "Netdata";
  appIcon = "netdata";
  appPlatform = "nixos";
  appDescription = "Real-time performance and health monitoring";
  appUrl = "https://www.netdata.cloud";
  appPinnedVersion = pkgs.netdata.version;

  cfg = config.homelab.features.${appName};

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";
  monitoringURL = internalURL;

in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = lib.mkMerge [
    {
      homelab.features.${appName} = {
        appInfos = {
          category = appCategory;
          displayName = appDisplayName;
          icon = appIcon;
          platform = appPlatform;
          url = appUrl;
          description = appDescription;
          pinnedVersion = appPinnedVersion;
          serviceURL = exposedURL;
        };
      };
    }

    (lib.mkIf cfg.enable {
      homelab.features.${appName} = {
        homepage = mkIf config.services.homepage-dashboard.enable {
          icon = appIcon;
          href = exposedURL;
          description = "${appDescription}  [${cfg.serviceDomain}]";
          siteMonitor = monitoringURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = "${monitoringURL}/api/v1/info";
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          ui.hide-hostname = true;
        };
      };

      networking.firewall = mkFirewall cfg [ 443 ];

      homelab.alias = [ "${cfg.serviceDomain}" ];

      programs.bash.shellAliases = mkServiceAliases appName;

      services.netdata = {
        enable = true;

        package = pkgs.netdata.override {
          withCloudUi = true;
        };

        enableAnalyticsReporting = false;

        python.enable = false;

        config = {
          global = {
            "update every" = 2;
          };

          db = {
            "db" = "dbengine";
            "storage tiers" = 1;
            "dbengine multihost disk space MB" = 1024;
          };

          web = {
            "bind to" = "127.0.0.1";
            "default port" = listenHttpPort;
          };

          "plugin:apps" = {
            "enabled" = "yes";
            "update every" = 2;
          };
        };
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
              Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https: wss:;"

              # Modern cross-origin isolation headers.
              Cross-Origin-Opener-Policy "same-origin"
              Cross-Origin-Resource-Policy "same-origin"

              # Cross-domain policy.
              X-Permitted-Cross-Domain-Policies "none"
            }
          '';
        };
      };
    })
  ];
}
