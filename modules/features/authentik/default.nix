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
  deprecatedMessage = ''
    Migrated to Zitadel. I migrated from Authentik to Zitadel because I encountered a migration issue from version 2025.10 to 2026.02. I found it unacceptable not to be able to migrate from a version only 4 months old (see the issue → [https://github.com/goauthentik/authentik/issues/20634](https://github.com/goauthentik/authentik/issues/20634)).
    // https://github.com/badele/nix-homelab/docs/features/zitadel.md
  '';

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
            deprecated = deprecatedMessage;
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
        users.users.authentik = {
          isSystemUser = true;
          group = "authentik";
          home = "/var/lib/authentik";
          createHome = true;
        };
        users.groups.authentik = { };

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

            echo "akadmin" > "$out/adminAccount"

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

        # Enable authentik in TLS mode with caddy reverse proxy if openFirewall is enabled
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
              reverse_proxy 127.0.0.1:${toString listenAuthentikPort}

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
                Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https: ws: wss:;"

                # Modern cross-origin isolation headers.
                Cross-Origin-Opener-Policy "same-origin-allow-popups"
                Cross-Origin-Resource-Policy "cross-origin"
                Cross-Origin-Embedder-Policy "unsafe-none"

                # Cross-domain policy.
                X-Permitted-Cross-Domain-Policies "none"
              }
            '';
          };
        };
      })
    ];
}
