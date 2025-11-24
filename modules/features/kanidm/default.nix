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
  appName = "kanidm";
  appCategory = "Core Services";
  appDisplayName = "Kanidm";
  appIcon = "kanidm";
  appPlatform = "nixos";
  appDescription = "Simple, secure and fast identity management platform";
  appUrl = "https://kanidm.com/";
  appPinnedVersion = pkgs.kanidmWithSecretProvisioning_1_6.version;
  deprecatedMessage = ''
    While lightweight and performant, Kanidm requires manual configuration for some operations. Migrated to Authentik for better web UI.
  '';

  cfg = config.homelab.features.${appName};

  listenHttpsPort = 8443;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "https://${config.services.kanidm.serverSettings.bindaddress}";
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
          siteMonitor = exposedURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = exposedURL;
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

      # Generate admin passwords
      clan.core.vars.generators.${appName} = {
        files.admin-password = {
          owner = config.systemd.services.kanidm.serviceConfig.User;
          group = config.systemd.services.kanidm.serviceConfig.Group;
        };
        files.idm-admin-password = {
          owner = config.systemd.services.kanidm.serviceConfig.User;
          group = config.systemd.services.kanidm.serviceConfig.Group;
        };

        runtimeInputs = [ pkgs.pwgen ];

        script = ''
          pwgen -s 48 1 > "$out"/admin-password
          pwgen -s 48 1 > "$out"/idm-admin-password
        '';
      };

      # Open firewall ports if enabled
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 443 ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = (mkServiceAliases appName) // { };

      # Kanidm service configuration
      services.kanidm = {
        enableServer = true;

        package = pkgs.kanidmWithSecretProvisioning_1_6;

        serverSettings = {
          domain = cfg.serviceDomain;
          origin = exposedURL;
          bindaddress = "[::]:${toString listenHttpsPort}";
          ldapbindaddress = "[::]:3636";

          # Use ACME certificates if openFirewall is enabled
          tls_chain = mkIf cfg.openFirewall "${
            config.security.acme.certs.${cfg.serviceDomain}.directory
          }/fullchain.pem";
          tls_key = mkIf cfg.openFirewall "${
            config.security.acme.certs.${cfg.serviceDomain}.directory
          }/key.pem";

          online_backup = {
            path = "/var/backup/${appName}/";
            schedule = "0 23 * * *";
            versions = 7;
          };
        };

        provision = {
          enable = true;
          autoRemove = true;
          adminPasswordFile = config.clan.core.vars.generators.${appName}.files.admin-password.path;
          idmAdminPasswordFile = config.clan.core.vars.generators.${appName}.files.idm-admin-password.path;

          groups.idm_all_persons = { };
        };
      };

      # Ensure kanidm starts after ACME certificates
      systemd.services.kanidm = mkIf cfg.openFirewall {
        after = [ "acme-${cfg.serviceDomain}.service" ];
        wants = [ "acme-${cfg.serviceDomain}.service" ];
        serviceConfig = {
          SupplementaryGroups = [ config.security.acme.certs.${cfg.serviceDomain}.group ];
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
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection $connection_upgrade;
            '';
          };

          extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
        };
      };

      #############################################################################
      # Backup
      #############################################################################
      clan.core.state.${appName} = {
        folders = [ "/var/backup/${appName}" ];
      };

    })
  ];
}
