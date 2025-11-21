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
  appName = "authentik";
  appDisplayName = "authentik";
  appCategory = "Core Services";
  appIcon = "authentik";
  appPlatform = "nixos";

  cfg = config.homelab.features.${appName};

  # TODO: get dynamically from pkgs
  appDescription = "The authentication glue you need. ";
  appUrl = "https://github.com/goauthentik/authentik";
  appPinnedVersion = "2025.10.12";

  listenAuthentikPort = 9000;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenAuthentikPort}";
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
          email = {
            host = "smtp.gmail.com";
            port = 587;
            username = config.homelab.stmpAccountUsername;
            from = config.homelab.stmpAccountUsername;
            use_tls = true;
            use_ssl = false;
          };
          disable_startup_analytics = true;
          avatars = "gravatar, initials";
        };
        description = ''
          ${appDisplayName} configuration. Refer to
          <https://docs.goauthentik.io/install-config/configuration>
          for details on supported values.
        '';
      };
      productName = mkOption {
        type = str;
        default = "";
        description = "Product name add on description";
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
        clan.core.vars.generators.gmail-application-password = {
          prompts."token" = {
            description = "Please insert your GMail application password";
            persist = true;
          };
        };

        clan.core.vars.generators.${appName} = {
          files = {
            adminAccount = {
              secret = false;
              value = "akadmin";
            };

            envfile = {
              owner = "authentik";
              group = "authentik";
            };
          };

          dependencies = [
            "gmail-application-password"
          ];

          runtimeInputs = [
            pkgs.pwgen
          ];

          script = ''
            SECRET_KEY="$(pwgen -s 64 1)"
            BOOTSTRAP_PASSWORD="$(pwgen -s 64 1)"
            BOOTSTRAP_TOKEN="$(pwgen -s 64 1)"
            GMAIL_APP_PASSWORD="$(cat $in/gmail-application-password/token)"

            cat > "$out/envfile" << EOF
            AUTHENTIK_SECRET_KEY=$SECRET_KEY
            AUTHENTIK_EMAIL__PASSWORD=$GMAIL_APP_PASSWORD

            AUTHENTIK_BOOTSTRAP_PASSWORD=$BOOTSTRAP_PASSWORD
            AUTHENTIK_BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN
            AUTHENTIK_BOOTSTRAP_EMAIL=${config.homelab.domainEmailAdmin}

            EOF
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
          "@service-${appName}-config" =
            "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
        };

        # Enable authentik service
        services.${appName} = {
          enable = true;
          environmentFile = config.clan.core.vars.generators.${appName}.files.envfile.path;
          settings = cfg.settings;
        };

        # Enable authentik in TLS mode with nginx reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            # Use wildcard domain
            useACMEHost = config.homelab.domain;
            forceSSL = true;

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString listenAuthentikPort}";
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
                # add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;
                add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https: ws: wss:;" always;

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
