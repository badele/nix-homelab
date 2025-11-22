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
  appName = "pawtunes";
  appCategory = "Essentials";
  appDisplayName = "Pawtunes";
  appIcon = "airsonic";
  appPlatform = "podman";
  appDescription = "The Ultimate HTML5 Internet Radio Player";
  appUrl = "https://github.com/Jackysi/PawTunes";
  appImage = "jackyprahec/pawtunes";
  appPinnedVersion = "1.0.6";
  appPath = "/data/podman/pawtunes";
  deprecatedMessage = ''
    This feature is deprecated due to Docker image initialization complexity.

    Recommended alternative: Use the simpler Radio application which provides
    a lightweight internet radio player without the Docker initialization overhead
    // https://github.com/pinpox/radio

  '';

  cfg = config.homelab.features.${appName};

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  containerUid = 33; # www-data
  containerGid = 33; # www-data

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUid;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGid;

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

        #######################################################################
        # Monitoring
        #######################################################################
        homelab.features.${appName} = {
          homepage = mkIf cfg.enable {
            icon = "sh-${appIcon}";
            href = exposedURL;
            description = appDescription;
            siteMonitor = internalURL;
          };

          gatus = mkIf cfg.enable {
            name = appDisplayName;
            url = internalURL;
            group = appCategory;
            type = "HTTP";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
              # ''[BODY] == pat(*"version": "${appPinnedVersion}"*)''
            ];
          };

        };

        #######################################################################
        # Service
        #######################################################################

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
        };

        systemd.tmpfiles.rules = [
          # Application data
          "d ${appPath} 0751 root root -"
          "d ${appPath}/data 0750 ${toString hostUid} ${toString hostGid} -"
          "d ${appPath}/data/cache 0750 ${toString hostUid} ${toString hostGid} -"
          "d ${appPath}/inc 0750 ${toString hostUid} ${toString hostGid} -"
          "d ${appPath}/inc/config 0750 ${toString hostUid} ${toString hostGid} -"
          "d ${appPath}/inc/locale 0750 ${toString hostUid} ${toString hostGid} -"

          # Backup directory
          "d /var/backup/pawtunes 0750 root root -"
        ];

        virtualisation.oci-containers.containers.${appName} = {
          image = "${appImage}:${appPinnedVersion}";
          autoStart = true;
          ports = [ "${toString listenHttpPort}:80" ];

          volumes = [
            "${appPath}/inc/config:/var/www/html/inc/config"
            "${appPath}/inc/locale:/var/www/html/inc/locale"
            "${appPath}/data:/var/www/html/data"
          ];

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
            forceSSL = true;
            enableACME = true;

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

            extraConfig = ''
              access_log /var/log/nginx/public.log vcombined;
            '';
          };
        };

      })
    ];
}
