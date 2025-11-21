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
  appName = "lldap";
  appCategory = "Core Services";
  appDisplayName = "LLDAP";
  appPlatform = "nixos";
  appIcon = "lldap";
  appUrl = pkgs.${appName}.meta.homepage;
  appDescription = "${pkgs.${appName}.meta.description}";
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;
  listenLDAPPort = listenHttpPort + 1;

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

      ldapDomain = mkOption {
        type = str;
        default = "dc=homelab,dc=lan";
        description = "Base DN for the LDAP directory";
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
            url = appUrl;
            description = appDescription;
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
            description = "${appDescription} [${cfg.serviceDomain}]";
            siteMonitor = internalURL;
          };

          gatus = mkIf config.services.gatus.enable {
            name = appDisplayName;
            url = "${internalURL}/api/health";
            group = appCategory;
            type = "HTTP";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
              "[BODY] == pat(*LLDAP Administration*)"
            ];
            ui.hide-hostname = true;
          };

        };

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          listenLDAPPort
          443
        ];

        users.users.lldap = {
          isSystemUser = true;
          description = "LLDAP service user";
          home = "/var/lib/lldap";
          createHome = true;
          shell = pkgs.bash;
          group = "lldap";
        };

        users.groups.lldap = { };

        clan.core.vars.generators.lldap = {
          files.jwt-secret = {
            owner = "lldap";
            group = "lldap";
          };
          files.password = {
            owner = "lldap";
            group = "lldap";
          };
          files.envfile = {
            owner = "lldap";
            group = "lldap";
          };

          runtimeInputs = [
            pkgs.pwgen
          ];

          script = ''
            pwgen -s 32 1 > "$out/jwt-secret"
            pwgen -s 16 1 > "$out/password"

            KEYSEED="$(pwgen -s 32 1)"
            cat > "$out/envfile" << EOF
            LLDAP_KEY_SEED=$KEYSEED
            EOF
          '';
        };

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        services.lldap = {
          enable = true;

          settings = {
            http_port = listenHttpPort;
            ldap_port = listenLDAPPort;

            ldap_base_dn = cfg.ldapDomain;
          };

          environment = {
            LLDAP_LDAP_BASE_DN = cfg.ldapDomain;
            LLDAP_JWT_SECRET_FILE = config.clan.core.vars.generators.${appName}.files."jwt-secret".path;
            LLDAP_LDAP_USER_PASS_FILE = config.clan.core.vars.generators.${appName}.files."password".path;
          };

          environmentFile = config.clan.core.vars.generators.${appName}.files."envfile".path;
        };

        # Enable lldap in TLS mode with nginx reverse proxy if openFirewall is enabled

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
                # Force HTTPS (for 1 year)
                add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

                # XSS and clickjacking protection
                add_header X-Frame-Options "SAMEORIGIN" always;

                # No execution of untrusted MIME types
                add_header X-Content-Type-Options "nosniff" always;

                # Send only domain with URL referer


                add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;

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
