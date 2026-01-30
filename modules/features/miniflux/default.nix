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
  appName = "miniflux";
  appCategory = "Essentials";
  appDisplayName = "Miniflux";
  appIcon = "miniflux";
  appPlatform = "nixos";
  appDescription = "Minimalist and opinionated feed reader";
  appUrl = "https://miniflux.app";
  appPinnedVersion = pkgs.${appName}.version;
  appSubDomain = head (splitString "." cfg.serviceDomain);

  cfg = config.homelab.features.${appName};

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
      enable = mkEnableOption appName;

      authDomain = mkOption {
        type = str;
        default = "${config.homelab.features.authentik.serviceDomain}";
        description = "OIDC service domain name";
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
  config = mkMerge [
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
          ];
          ui.hide-hostname = true;
        };
      };

      #######################################################################
      # Service
      #######################################################################
      clan.core.vars.generators.miniflux = {
        files.oauth2-client-secret = { };
        files.miniflux-env = { };

        runtimeInputs = [
          pkgs.pwgen
        ];

        script = ''
          CLIENTSECRET="$(pwgen -s 64 1)"
          ADMINPASSWORD="$(pwgen -s 48 1)"

          echo "$CLIENTSECRET" > "$out/oauth2-client-secret"

          cat > "$out/miniflux-env" << EOF
          OAUTH2_CLIENT_SECRET=$CLIENTSECRET
          ADMIN_USERNAME=admin
          ADMIN_PASSWORD=$ADMINPASSWORD
          EOF
        '';
      };

      # Open firewall ports if openFirewall is enabled
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 443 ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = (mkServiceAliases appName) // { };

      # User and group for miniflux
      users.users.miniflux = {
        isSystemUser = true;
        group = "miniflux";
        createHome = true;
        homeMode = "0774";
      };

      users.groups.miniflux = { };

      # Miniflux service configuration
      services.miniflux = {
        enable = true;
        createDatabaseLocally = true;

        config = {
          LISTEN_ADDR = "127.0.0.1:${toString listenHttpPort}";
          BASE_URL = exposedURL;
          HTTP_CLIENT_MAX_BODY_SIZE = "33554432";

          # Authentik OAuth2 configuration
          OAUTH2_PROVIDER = "oidc";
          OAUTH2_CLIENT_ID = "${appSubDomain}-${appName}";
          OAUTH2_REDIRECT_URL = "${exposedURL}/oauth2/oidc/callback";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${cfg.authDomain}/application/o/${appSubDomain}-${appName}/";
          OAUTH2_USER_CREATION = "1";
        };

        adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."miniflux-env".path;
      };

      # Nginx configuration
      services.nginx.virtualHosts = mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          # Use wildcard domain
          useACMEHost = config.homelab.domain;
          forceSSL = true;

          locations."/" = {
            proxyPass = internalURL;
            recommendedProxySettings = true;
            proxyWebsockets = true;

            # Security headers
            extraConfig = ''
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

          extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
        };
      };

      #############################################################################
      # Backup
      #############################################################################
      # TODO: Implement PostgreSQL backup with clan.core.postgresql
      # clan.postgresql.databases = {
      #   miniflux = {
      #     service = "miniflux";
      #     restore = {
      #       stopOnRestore = [ "miniflux" ];
      #     };
      #   };
      # };

    })
  ];
}
