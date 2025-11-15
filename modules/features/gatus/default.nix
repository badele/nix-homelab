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
  appName = "gatus";
  cfg = config.homelab.features.${appName};

  listenHttpPort = config.homelab.portRegistry.${appName}.httpPort;

  # Service URL: use nginx domain if firewall is open, otherwise use direct IP:port
  serviceURL =
    if cfg.openFirewall then
      "https://${cfg.serviceDomain}"
    else
      "http://127.0.0.1:${toString listenHttpPort}";

  # Collect all features with homepage configuration
  featuresWithGatus = lib.filterAttrs (
    name: feature: feature.enable or false && feature.gatus != null
  ) config.homelab.features;

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
            category = "System Health";
            displayName = "Gatus";
            icon = "gatus";
            platform = "nixos";
            description = "${pkgs.${appName}.meta.description}";
            url = pkgs.${appName}.meta.homepage;
            pinnedVersion = pkgs.${appName}.version;
          };

        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

        homelab.features.${appName} = {
          homepage = mkIf cfg.enable {
            icon = cfg.appInfos.icon;
            href = serviceURL;
            description = cfg.appInfos.description;
            siteMonitor = serviceURL;
          };
        };

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
        };

        # Enable Gatus service
        services.${appName} = {
          enable = true;
          settings = {
            web.port = listenHttpPort;
            storage = {
              type = "sqlite";
              path = "/var/lib/gatus/gatus.db";
            };

            endpoints = lib.mapAttrsToList (name: feature: feature.gatus) featuresWithGatus;
          };
        };

        # Enable gatus in TLS mode with nginx reverse proxy if openFirewall is enabled
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            forceSSL = true;
            enableACME = true;

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
