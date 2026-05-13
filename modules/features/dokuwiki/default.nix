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

      # Caddy configuration
      services.caddy.virtualHosts = mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          logFormat = ''
            output file /var/log/caddy/public.log {
              mode 0644
            }
            format json
          '';

          extraConfig = ''
            # URL rewriting for DokuWiki clean URLs.
            @media path_regexp media ^/_media/(.*)$
            rewrite @media /lib/exe/fetch.php?media={re.media.1}

            @detail path_regexp detail ^/_detail/(.*)$
            rewrite @detail /lib/exe/detail.php?media={re.detail.1}

            @export path_regexp export ^/_export/([^/]+)/(.*)$
            rewrite @export /doku.php?do=export_{re.export.1}&id={re.export.2}

            @clean {
              not path /lib/* /_media/* /_detail/* /_export/* /doku.php* /feed.php* /install.php*
              path_regexp clean ^/(.*)$
            }
            rewrite @clean /doku.php?id={re.clean.1}

            reverse_proxy ${internalURL}

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
              # DokuWiki needs 'unsafe-inline' and CDN access for plugins and OAuth.
              Content-Security-Policy "default-src 'self'; font-src 'self' data: https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; img-src 'self' data: https: http:; media-src 'self' blob: https:; connect-src 'self' https: wss:; frame-ancestors 'self';"

              # Modern cross-origin isolation headers relaxed for OAuth flows.
              Cross-Origin-Opener-Policy "same-origin-allow-popups"
              Cross-Origin-Resource-Policy "cross-origin"

              # Cross-domain policy.
              X-Permitted-Cross-Domain-Policies "none"
            }
          '';
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
