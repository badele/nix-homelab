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
  appName = "authelia";
  appCategory = "Core Services";
  appDisplayName = "Authelia";
  appIcon = "authelia";
  appPlatform = "nixos";
  appDescription = "Single Sign-On multi-factor portal for web apps";
  appUrl = "https://www.authelia.com/";
  appPinnedVersion = pkgs.${appName}.version;
  deprecatedMessage = ''
    Migrated from Authelia to Authentik. While Authentik requires some manual configuration, it offers more features and better integration capabilities.
    // https://github.com/badele/nix-homelab/docs/features/authentik.md

  '';

  cfg = config.homelab.features.${appName};

  listenHttpPort = 9091;
  base_dn = "dc=homelab,dc=lan";

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";

  secrets_permission = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
  };
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

      baseDN = mkOption {
        type = str;
        default = base_dn;
        description = "LDAP base DN";
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
          deprecated = deprecatedMessage;
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

      # Gmail application password prompt (one-time)
      clan.core.vars.generators.gmail-application-password = {
        prompts."token" = {
          description = "Please insert your GMail application password";
          persist = true;
        };
      };

      # Generate encryption key once (critical - don't regenerate!)
      clan.core.vars.generators.authelia-encryption-key = {
        files.storage-encryption-key = { };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 64 1 > "$out"/storage-encryption-key
        '';
      };

      # Generate all authelia secrets
      clan.core.vars.generators.authelia = {
        files.gmail-application-password = secrets_permission;
        files.jwt-secret = secrets_permission;
        files.session-secret = secrets_permission;
        files.storage-encryption-key = secrets_permission;
        files.jwks-private-key = secrets_permission;
        files.jwks-certificate = secrets_permission;
        files.hmac-secret = secrets_permission;
        files.lldap-password = secrets_permission;

        dependencies = [
          "gmail-application-password"
          "authelia-encryption-key"
        ];

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
          pkgs.openssl
        ];

        script = ''
          pwgen -s 64 1 > "$out"/jwt-secret
          pwgen -s 64 1 > "$out"/session-secret
          pwgen -s 64 1 > "$out"/hmac-secret
          pwgen -s 64 1 > "$out"/lldap-password

          authelia crypto certificate rsa generate \
            --common-name "${cfg.serviceDomain}" \
            --bits 2048 \
            --file.private-key jwks-private-key \
            --file.certificate jwks-certificate \
            --directory "$out"

          cat $in/authelia-encryption-key/storage-encryption-key > "$out"/storage-encryption-key
          cat $in/gmail-application-password/token > $out/gmail-application-password
        '';
      };

      # Create authelia data directory
      systemd.tmpfiles.rules = [
        "d /var/lib/authelia-main 0750 authelia-main authelia-main -"
      ];

      # Open firewall ports if enabled
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 443 ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = (mkServiceAliases appName) // { };

      # Authelia service configuration
      services.authelia.instances.main = {
        enable = true;

        secrets = {
          jwtSecretFile = config.clan.core.vars.generators.authelia.files.jwt-secret.path;
          sessionSecretFile = config.clan.core.vars.generators.authelia.files.session-secret.path;
          storageEncryptionKeyFile =
            config.clan.core.vars.generators.authelia.files.storage-encryption-key.path;
          oidcIssuerPrivateKeyFile = config.clan.core.vars.generators.authelia.files.jwks-private-key.path;
          oidcHmacSecretFile = config.clan.core.vars.generators.authelia.files.hmac-secret.path;
        };

        environmentVariables = {
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
            config.clan.core.vars.generators.authelia.files.gmail-application-password.path;
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
            config.clan.core.vars.generators.authelia.files.lldap-password.path;
        };

        settings = {
          theme = "dark";
          default_redirection_url = "https://${config.homelab.domain}";

          server = {
            address = "tcp://127.0.0.1:${toString listenHttpPort}";
            asset_path = "";
            headers.csp_template = "";
          };

          log = {
            level = "info";
            format = "text";
          };

          webauthn = {
            disable = false;
            display_name = "Ma Cabane";
          };

          totp = {
            disable = false;
            issuer = config.homelab.domain;
            algorithm = "sha1";
            digits = 6;
            period = 30;
            skew = 1;
          };

          authentication_backend = {
            refresh_interval = "1m";
            ldap = {
              implementation = "custom";
              address = "ldap://127.0.0.1:3890";
              base_dn = cfg.baseDN;
              users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))";
              groups_filter = "(uniqueMember={dn})";
              user = "uid=authelia,ou=people,${cfg.baseDN}";
            };
          };

          session = {
            name = "authelia_session";
            domain = config.homelab.domain;
            expiration = "1h";
            inactivity = "5m";
            remember_me = "1M";
          };

          regulation = {
            max_retries = 3;
            find_time = "2m";
            ban_time = "5m";
          };

          storage = {
            local = {
              path = "/var/lib/authelia-main/db.sqlite3";
            };
          };

          notifier = {
            disable_startup_check = false;
            smtp = {
              address = "submission://smtp.gmail.com:587";
              username = config.homelab.domainEmailAdmin;
              sender = "admin@${config.homelab.domain}";
            };
          };

          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = cfg.serviceDomain;
                policy = "bypass";
              }

              # Miniflux
              {
                domain = "journaliste.${config.homelab.domain}";
                policy = "one_factor";
                subject = [ "group:sso-miniflux" ];
              }

              # Linkding
              {
                domain = "bonnes-adresses.${config.homelab.domain}";
                policy = "one_factor";
                subject = [ "group:sso-linkding" ];
              }

              # Dokuwiki
              {
                domain = "encyclopedie.${config.homelab.domain}";
                policy = "one_factor";
                subject = [ "group:sso-dokuwiki" ];
              }

              # Grafana
              {
                domain = "lampiotes.${config.homelab.domain}";
                policy = "one_factor";
                subject = [
                  "group:grafana-superadmins"
                  "group:grafana-admins"
                  "group:grafana-editors"
                  "group:grafana-viewers"
                ];
              }

              # Notes
              {
                domain = "notes.${config.homelab.domain}";
                policy = "one_factor";
                subject = [
                  "group:notes-admin"
                  "group:notes-read"
                  "group:notes-write"
                ];
              }

              # Wiki
              {
                domain = "wiki.${config.homelab.domain}";
                policy = "one_factor";
                subject = [
                  "group:wiki-admin"
                  "group:wiki-read"
                  "group:wiki-write"
                ];
              }

              # Fallback: deny all other domains
              {
                domain = "*.${config.homelab.domain}";
                policy = "deny";
              }
            ];
          };
        };
      };

      # Ensure authelia starts after ACME certificates
      systemd.services.authelia-main = mkIf cfg.openFirewall {
        after = [ "acme-${config.homelab.domain}.service" ];
        wants = [ "acme-${config.homelab.domain}.service" ];
        serviceConfig = {
          SupplementaryGroups = [ config.security.acme.certs.${config.homelab.domain}.group ];
        };
      };

      # Nginx configuration
      services.nginx.virtualHosts = mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          # Use wildcard or specific domain certificate
          useACMEHost = config.homelab.domain;
          forceSSL = true;

          locations."/" = {
            proxyPass = internalURL;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $http_host;
              proxy_set_header X-Forwarded-Uri $request_uri;
              proxy_set_header X-Forwarded-Ssl on;
              proxy_redirect http:// https://;
              proxy_http_version 1.1;
              proxy_set_header Connection $connection_upgrade;
              proxy_set_header Upgrade $http_upgrade;
              proxy_cache_bypass $http_upgrade;
            '';
          };

          extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
        };
      };

      #############################################################################
      # Backup
      #############################################################################
      clan.core.state.authelia = {
        folders = [ "/var/lib/authelia-main" ];
      };

    })
  ];
}
