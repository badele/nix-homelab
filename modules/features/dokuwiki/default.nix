{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
}:
with lib;
with types;

let
  appName = "dokuwiki";
  appCategory = "Essentials";
  appDisplayName = "DokuWiki";
  appIcon = "dokuwiki";
  appPlatform = "podman";
  appDescription = "Simple to use and highly versatile wiki software";
  appUrl = "https://www.dokuwiki.org/";
  appPinnedVersion = "version-2025-05-14b";
  appImage = "linuxserver/dokuwiki";
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  containerUID = 1000;
  containerGID = 1000;

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUID;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGID;

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
        manualConfiguration = true;

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

      clan.core.vars.generators.${appName} = {
        files.oauth2-client-secret = { };

        runtimeInputs = [
          pkgs.pwgen
        ];

        script = ''
          CLIENTSECRET="$(pwgen -s 64 1)"

          echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
        '';
      };

      # Create application directories
      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0750 root root -"
        "d ${appPath}/config 0750 ${toString hostUid} ${toString hostGid} -"

        # Backup directory
        "d /var/backup/${appName} 0750 root root -"
      ];

      # Open firewall ports if enabled
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 443 ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = (mkPodmanAliases appName) // { };

      # DokuWiki container
      virtualisation.oci-containers.containers.${appName} = {
        image = "${appImage}:${appPinnedVersion}";
        autoStart = true;
        ports = [ "127.0.0.1:${toString listenHttpPort}:80" ];

        volumes = [
          "${appPath}/config:/config"
        ];

        environment = {
          PUID = toString containerUID;
          PGID = toString containerGID;
        };

        extraOptions = [
          "--add-host=${cfg.authDomain}:host-gateway"
          "--subgidname=root"
          "--subuidname=root"
        ];
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

            extraConfig = ''
              # URL rewriting for DokuWiki
              # This allows clean URLs like /wiki/page instead of /doku.php?id=wiki:page
              rewrite ^/_media/(.*)              /lib/exe/fetch.php?media=$1  last;
              rewrite ^/_detail/(.*)             /lib/exe/detail.php?media=$1 last;
              rewrite ^/_export/([^/]+)/(.*)     /doku.php?do=export_$1&id=$2 last;
              rewrite ^/(?!lib/|_media|_detail|_export|doku\.php|feed\.php|install\.php)([^\?]*)(\?(.*))?$ /doku.php?id=$1&$3 last;

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
              # Note: DokuWiki needs 'unsafe-inline' for inline scripts/styles and CDN access
              # Relaxed CSP for DokuWiki compatibility with plugins and OAuth
              add_header Content-Security-Policy "default-src 'self'; font-src 'self' data: https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; img-src 'self' data: https: http:; media-src 'self' blob: https:; connect-src 'self' https: wss:; frame-ancestors 'self';" always;

              # Modern CORS headers (relaxed for OAuth flows)
              add_header Cross-Origin-Opener-Policy "same-origin-allow-popups" always;
              add_header Cross-Origin-Resource-Policy "cross-origin" always;

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
      clan.core.state.${appName} = {
        folders = [ appPath ];

        # Backup service data locally, used by borgbackup
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              config.systemd.package
              pkgs.coreutils
              pkgs.rsync
            ]
          }

          service_status=$(systemctl is-active ${appName})
          if [ "$service_status" = "active" ]; then
            systemctl stop ${appName}
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/${appName}/
            systemctl start ${appName}
          fi
        '';

        # Restore files to service (files restored by borgbackup)
        postRestoreScript = ''
          export PATH=${
            lib.makeBinPath [
              config.systemd.package
              pkgs.coreutils
              pkgs.rsync
            ]
          }

          service_status="$(systemctl is-active ${appName})"

          if [ "$service_status" = "active" ]; then
            systemctl stop ${appName}

            # Backup current dokuwiki data locally
            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            # Restore from borgbackup
            rsync -avH --delete --numeric-ids /var/backup/${appName}/ "${appPath}/"

            systemctl start ${appName}
          fi
        '';
      };

    })
  ];
}
