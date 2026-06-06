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
  appName = "wastebin";
  appCategory = "Essentials";
  appDisplayName = "Wastebin";
  appIcon = "sh-wastebin";
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

        #######################################################################
        # Monitoring
        #######################################################################
        homelab.features.${appName} = {
          homepage = mkIf config.services.homepage-dashboard.enable {
            icon = "${appIcon}";
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
              # ''[BODY] == pat(*"version": "${appPinnedVersion}"*)''
            ];
            ui.hide-hostname = true;
          };

        };

        #######################################################################
        # Service
        #######################################################################

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
        };

        clan.core.vars.generators.wastebin = {
          files.envfile = { };
          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            echo "WASTEBIN_PASSWORD_SALT=$(pwgen -s 64 1)" >> $out/envfile
            echo "WASTEBIN_SIGNING_KEY=$(pwgen -s 64 1)" >> $out/envfile
          '';
        };

        services.wastebin = {
          enable = true;

          secretFile = config.clan.core.vars.generators."wastebin".files."envfile".path;

          settings = {
            WASTEBIN_ADDRESS_PORT = "127.0.0.1:${toString listenHttpPort}";
            WASTEBIN_TITLE = "codes";
            WASTEBIN_BASE_URL = "https://codes.ma-cabane.eu";
          };
        };

        services.caddy.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
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
