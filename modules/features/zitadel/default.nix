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

  adminAccount = "zitadel-admin";

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
        default = { };
        description = ''
          ${appDisplayName} extra runtime configuration (merged with defaults). Refer to
          <https://zitadel.com/docs/self-hosting/manage/configure>
          for details on supported values.
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

        # Gmail application password prompt (one-time)
        clan.core.vars.generators.gmail-apps-zitadel-password = {
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

            masterkey = {
              owner = "zitadel";
              group = "zitadel";
            };

            # YAML file with secrets (admin password) passed via extraStepsPaths
            steps-secrets = {
              owner = "zitadel";
              group = "zitadel";
            };
          };

          # dependencies = [
          #   "gmail-application-password"
          # ];

          runtimeInputs = [
            pkgs.pwgen
          ];

          script = ''
            # Generate 32-byte master key for ZITADEL encryption
            # TODO: fix the zitadel default password. zitadel define "Password1!", I CANNONT CHANGE IT
            printf %s "$(pwgen -s 32 1)"  > "$out/masterkey"

            # Generate admin password
            # USER: $adminAccount@<INSTANCENAME>.douane.ma-cabane.eu
            ADMIN_PASSWORD="$(pwgen -s 8 1)-$(pwgen -s 8 1)"

            # Store in clan vars (only for information)
            echo "${adminAccount}" > "$out/adminAccount"

            # Generate steps secrets YAML (overrides FirstInstance.Org.Human.Password)
            cat > "$out/steps-secrets" << EOF
            FirstInstance:
              Org:
                Human:
                  Password: $ADMIN_PASSWORD
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
          "@service-${appName}-status" = "systemctl status zitadel";
        };

        # PostgreSQL database for ZITADEL
        services.postgresql = {
          enable = true;
          ensureUsers = [
            {
              name = "zitadel";
              ensureDBOwnership = true;
            }
          ];
          ensureDatabases = [
            "zitadel"
          ];

          authentication = lib.mkBefore ''
            # TYPE    DATABASE        USER            ADDRESS                 METHOD
            # local = unix socket, host = TCP/IP
            # DATABASE = target database name (or "all")
            # USER = PostgreSQL role name (or "all")
            # ADDRESS = IP range (only for host type)
            # METHOD = auth method (trust=no password, peer=linux user must match PG role)

            # ZITADEL: trust for start-from-init (user zitadel runs as postgres admin)
            local   zitadel         zitadel                                 trust
            local   zitadel         postgres                                trust
            local   postgres        postgres                                trust
          '';
        };

        # Ensure ZITADEL starts after PostgreSQL is ready
        systemd.services.zitadel = {
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
        };

        # Enable ZITADEL service
        services.zitadel = {
          enable = true;
          masterKeyFile = config.clan.core.vars.generators.${appName}.files.masterkey.path;
          tlsMode = cfg.tlsMode;

          extraStepsPaths = [
            config.clan.core.vars.generators.${appName}.files.steps-secrets.path
          ];

          settings = {
            Port = listenZitadelPort;
            ExternalDomain = cfg.serviceDomain;
            ExternalPort = 443;
            ExternalSecure = true;
            Database.postgres = {
              Host = "/run/postgresql";
              Port = 5432;
              Database = "zitadel";
              User = {
                Username = "zitadel";
                SSL.Mode = "disable";
              };
              Admin = {
                Username = "postgres";
                SSL.Mode = "disable";
              };
            };
            Telemetry.Enabled = false;
          }
          // cfg.settings;
          steps = {
            FirstInstance = {
              InstanceName = "ZITADEL";
              DefaultLanguage = "fr";
              LoginPolicy.AllowRegister = false;

              Org.Human = {
                Name = "ZITADEL";
                UserName = adminAccount;
                FirstName = "Admin";
                LastName = "Homelab";
                PasswordChangeRequired = false;
                Email = {
                  Address = "${adminAccount}@${cfg.serviceDomain}";
                  Verified = true;
                };
              };
            };
          };
        };

        # Enable ZITADEL in TLS mode with nginx reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            # Use wildcard domain
            useACMEHost = config.homelab.domain;
            forceSSL = true;

            # HTTP/2 is required for gRPC support
            http2 = true;

            locations."/" = {
              # Use grpc_pass for ZITADEL (serves both gRPC and HTTP via h2c)
              extraConfig = ''
                grpc_pass grpc://127.0.0.1:${toString listenZitadelPort};
                grpc_set_header Host $host;
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
