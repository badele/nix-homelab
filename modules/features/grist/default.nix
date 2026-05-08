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
  authdomain = "douane.${config.homelab.domain}";

  appName = "grist";
  appCategory = "Essentials";
  appDisplayName = "grist";
  appIcon = "grist";
  appPlatform = "podman";
  appDescription = "Next generation of spreadsheets";
  appUrl = "https://github.com/sissbruecker/grist";
  appImage = "gristlabs/grist";
  appPinnedVersion = "1.7.7";
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  containerUID = 1001; # www-data
  containerGID = 1001; # www-data

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

      defaultEmailDomain = mkOption {
        type = str;
        default = config.homelab.domainEmailAdmin;
        description = "Default email domain for new users";
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
          icon = "sh-${appIcon}";
          href = exposedURL;
          description = "${appDescription}  [${cfg.serviceDomain}]";
          #TODO: switch to internalURL if you want to monitor via direct access
          # use domain detection
          siteMonitor = exposedURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          #TODO: switch to internalURL if you want to monitor via direct access
          # use domain detection
          url = exposedURL;
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
      clan.core.vars.generators.${appName} = {
        files.envfile = { };

        runtimeInputs = [
          pkgs.pwgen
        ];

        script = ''
          SESSIONSECRET="$(pwgen -s 48 1)"

          cat > "$out/envfile" << EOF
          GRIST_SESSION_SECRET=$SESSIONSECRET
          EOF
        '';
      };

      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0750 root root -"
        "d ${appPath}/persist 0750 ${toString hostUid} ${toString hostGid} -"

        # Backup directory
        "d /var/backup/${appName} 0750 root root -"
      ];

      # Open firewall ports if openFirewall is enabled
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        443
      ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = (mkPodmanAliases appName) // {
      };

      virtualisation.oci-containers.containers.${appName} = {
        image = "${appImage}:${appPinnedVersion}";
        autoStart = true;
        ports = [ "127.0.0.1:${toString listenHttpPort}:8484" ];

        volumes = [
          "${appPath}/persist:/persist"
        ];

        environmentFiles = [
          config.clan.core.vars.generators.${appName}.files."envfile".path
        ];

        environment = {
          GRIST_DEFAULT_EMAIL = config.homelab.features.${appName}.defaultEmailDomain;
          APP_HOME_URL = exposedURL;
        };

        extraOptions = [
          "--cap-drop=ALL"

          # for nginx
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
          "--cap-add=NET_BIND_SERVICE"
          "--subgidname=root"
          "--subuidname=root"
        ];
      };

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
              add_header Referrer-Policy "strict-origin-when-cross-origin" always;

              # Disable all unused browser features for better privacy
              add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

              # Allow only specific sources to load content (CSP)
              add_header Content-Security-Policy "default-src 'self'; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https:;" always;

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
      clan.core.state.${appName} = {
        folders = [ appPath ];
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

            # Backup current grist data locally
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
