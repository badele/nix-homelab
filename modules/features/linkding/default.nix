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

  appName = "linkding";
  appCategory = "Essentials";
  appDisplayName = "Linkding";
  appIcon = "linkding";
  appPlatform = "podman";
  appDescription = "Bookmark manager designed to be minimal, fast, and easy to set up";
  appUrl = "https://github.com/sissbruecker/linkding";
  appImage = "ghcr.io/sissbruecker/linkding";
  appPinnedVersion = "1.41.0-plus";
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  containerUID = 33; # www-data
  containerGID = 33; # www-data

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
          href = "${exposedURL}/bookmarks/shared";
          description = "${appDescription}  [${cfg.serviceDomain}]";
          siteMonitor = "${internalURL}/bookmarks/shared";
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = "${internalURL}/bookmarks/shared";
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
      clan.core.vars.generators.linkding = {
        files.oauth2-client-secret = { };
        files.digest-client-secret = { };
        files.envfile = { };

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
          pkgs.gnugrep
          pkgs.gawk
        ];

        script = ''
          CLIENTSECRET="$(pwgen -s 48 1)"
          ADMINPASSWORD="$(pwgen -s 16 1)"
          DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";

          echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
          echo "$DIGETSECRET" > "$out/digest-client-secret"

          cat > "$out/envfile" << EOF
          OIDC_RP_CLIENT_SECRET=$CLIENTSECRET
          LD_SUPERUSER_NAME=bookadmin
          LD_SUPERUSER_PASSWORD=$ADMINPASSWORD
          EOF
        '';
      };

      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0750 root root -"
        "d ${appPath}/data 0750 ${toString hostUid} ${toString hostGid} -"

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
        ports = [ "127.0.0.1:${toString listenHttpPort}:9090" ];

        volumes = [
          "${appPath}/data:/etc/linkding/data"
        ];

        environmentFiles = [
          config.clan.core.vars.generators."linkding".files."envfile".path
        ];

        environment = {
          LD_ENABLE_OIDC = "true";
          OIDC_OP_AUTHORIZATION_ENDPOINT = "https://${authdomain}/api/oidc/authorization";
          OIDC_OP_TOKEN_ENDPOINT = "https://${authdomain}/api/oidc/token";
          OIDC_OP_USER_ENDPOINT = "https://${authdomain}/api/oidc/userinfo";
          OIDC_OP_JWKS_ENDPOINT = "https://${authdomain}/jwks.json";
          OIDC_RP_CLIENT_ID = "linkding";
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
      clan.core.state.linkding = {
        folders = [ appPath ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              config.systemd.package
              pkgs.coreutils
              pkgs.rsync
            ]
          }

          service_status=$(systemctl is-active linkding)
          if [ "$service_status" = "active" ]; then
            systemctl stop linkding
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/linkding/
            systemctl start linkding
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

          service_status="$(systemctl is-active linkding)"

          if [ "$service_status" = "active" ]; then
            systemctl stop linkding

            # Backup current linkding data locally
            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            # Restore from borgbackup
            rsync -avH --delete --numeric-ids /var/backup/linkding/ "${appPath}/"

            systemctl start linkding
          fi
        '';
      };

    })
  ];
}
