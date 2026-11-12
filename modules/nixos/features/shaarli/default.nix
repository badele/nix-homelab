{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkFirewallInterfaces,
  mkRootlessPodmanAliases,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  mkRootlessPodmanService = (import ../../homelab/helpers.nix { inherit lib; }).mkRootlessPodmanService;

  appName = "shaarli";
  appCategory = "Essentials";
  appDisplayName = "Shaarli";
  appIcon = "shaarli";
  appPlatform = "podman";
  appDescription = "Personal, minimalist, super-fast, database free, bookmarking service - community repo";
  appUrl = "https://github.com/shaarli/Shaarli";
  appImage = "docker.io/shaarli/shaarli";
  appPinnedVersion = "v0.12.2";
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  cfg = config.homelab.features.${appName};

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  # shaarli runs as nginx (uid 100, gid 101) inside the container.
  # Remap uid 100 and gid 101 → 0 (pod-shaarli on host).
  containerUID = 100;
  containerGID = 101;
  uidmapOptions =
    let
      aboveUid = 65536 - containerUID - 1;
      aboveGid = 65536 - containerGID - 1;
    in
    [
      "--uidmap=0:1:${toString containerUID}"
      "--uidmap=${toString containerUID}:0:1"
      "--uidmap=${toString (containerUID + 1)}:${toString (containerUID + 1)}:${toString aboveUid}"
      "--gidmap=0:1:${toString containerGID}"
      "--gidmap=${toString containerGID}:0:1"
      "--gidmap=${toString (containerGID + 1)}:${toString (containerGID + 1)}:${toString aboveGid}"
    ];

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";
  monitoringURL = internalURL;
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

    (mkIf cfg.enable {

      #######################################################################
      # Monitoring
      #######################################################################
      homelab.features.${appName} = {
        homepage = mkIf config.services.homepage-dashboard.enable {
          icon = "sh-${appIcon}";
          href = exposedURL;
          description = "${appDescription}  [${cfg.serviceDomain}]";
          siteMonitor = monitoringURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = monitoringURL;
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
      systemd.tmpfiles.rules = [
        "d ${appPath} 0751 root root -"
        "d ${appPath}/data 0750 pod-${appName} pod-${appName} -"
        "d ${appPath}/cache 0750 pod-${appName} pod-${appName} -"
        "d /var/backup/${appName} 0750 root root -"
      ];

      networking.firewall.interfaces = mkFirewallInterfaces cfg [ 443 ];

      homelab.alias = [ "${cfg.serviceDomain}" ];

      programs.bash.shellAliases = mkRootlessPodmanAliases appName;

      services.caddy.virtualHosts = mkIf cfg.openFirewall {
        "${cfg.serviceDomain}" = {
          listenAddresses = resolveListenInterfaceAddresses appName cfg.listenInterfaces;
          logFormat = ''
            output file /var/log/caddy/public.log {
              mode 0644
            }
            format json
          '';

          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString listenHttpPort}

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
              # Shaarli needs 'unsafe-inline' for inline scripts/styles.
              Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data: https:; media-src 'self' blob: https:; connect-src 'self' https:; frame-ancestors 'self';"

              # Modern cross-origin isolation headers.
              Cross-Origin-Opener-Policy "same-origin"
              Cross-Origin-Resource-Policy "same-origin"
              Cross-Origin-Embedder-Policy "require-corp"

              # Cross-domain policy.
              X-Permitted-Cross-Domain-Policies "none"
            }
          '';
        };
      };

      #############################################################################
      # Backup
      #############################################################################
      clan.core.state.shaarli = {
        folders = [ appPath ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              config.systemd.package
              pkgs.coreutils
              pkgs.rsync
            ]
          }

          service_status=$(systemctl is-active pod-${appName})
          if [ "$service_status" = "active" ]; then
            systemctl stop pod-${appName}
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/shaarli/
            systemctl start pod-${appName}
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

          service_status="$(systemctl is-active pod-${appName})"

          if [ "$service_status" = "active" ]; then
            systemctl stop pod-${appName}

            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            rsync -avH --delete --numeric-ids /var/backup/shaarli/ "${appPath}/"

            systemctl start pod-${appName}
          fi
        '';
      };

    })

    (mkIf cfg.enable (mkRootlessPodmanService {
      inherit pkgs;
      name = appName;
      image = "${appImage}:${appPinnedVersion}";
      subUidStart = 100000 + config.homelab.portRegistry.${appName}.appId * 65536;
      ports = [ "127.0.0.1:${toString listenHttpPort}:80" ];
      volumes = [
        "${appPath}/data:/var/www/shaarli/data"
        "${appPath}/cache:/var/www/shaarli/cache"
      ];

      environment = lib.optionalAttrs (config.time.timeZone != null) {
        TZ = config.time.timeZone;
      };
      extraOptions = uidmapOptions ++ [
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=NET_BIND_SERVICE"
      ];
    }))
  ];
}
