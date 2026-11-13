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
  mkRootlessPodmanService =
    (import ../../homelab/helpers.nix { inherit lib; }).mkRootlessPodmanService;

  appName = "dokuwiki";
  appCategory = "Essentials";
  appDisplayName = "DokuWiki";
  appIcon = "dokuwiki";
  appPlatform = "podman";
  appDescription = "Simple to use and highly versatile wiki software";
  appUrl = "https://www.dokuwiki.org/";
  appPinnedVersion = "version-2025-05-14b";
  appImage = "docker.io/linuxserver/dokuwiki";
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

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
      podTraceSyscalls = mkEnableOption "Wrap podman run with strace (startup+runtime, no --uidmap; output: /tmp/dokuwiki-strace.log on service stop)";
      systemdTraceSyscalls = mkEnableOption "Attach strace to running podman via systemd ExecStartPost as root (runtime only, all images; output: /tmp/dokuwiki-strace.log on service stop)";
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
        "d ${appPath} 0751 root root -"
        "d ${appPath}/config 0750 pod-${appName} pod-${appName} -"

        # Backup directory
        "d /var/backup/${appName} 0750 root root -"
      ];

      # Open firewall ports if enabled
      networking.firewall.interfaces = mkFirewallInterfaces cfg [ 443 ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
      programs.bash.shellAliases = mkRootlessPodmanAliases appName;

      # Caddy configuration
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
            rewrite @clean /doku.php?id={re.clean.1}&{query}

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

          service_status=$(systemctl is-active pod-${appName})
          if [ "$service_status" = "active" ]; then
            systemctl stop pod-${appName}
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/${appName}/
            systemctl start pod-${appName}
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

          service_status="$(systemctl is-active pod-${appName})"

          if [ "$service_status" = "active" ]; then
            systemctl stop pod-${appName}

            # Backup current dokuwiki data locally
            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            # Restore from borgbackup
            rsync -avH --delete --numeric-ids /var/backup/${appName}/ "${appPath}/"

            systemctl start pod-${appName}
          fi
        '';
      };

    })

    # Rootless podman service under pod-dokuwiki system user
    (mkIf cfg.enable (
      let
        # linuxserver.io runs as abc (uid 1000, gid 1000).
        # PHP-FPM refuses uid 0, so we can't use PUID=0.
        # Remap uid/gid 1000 → 0 (pod-dokuwiki on host).
        containerUID = 1000;
        containerGID = 1000;
        uidmapOptions =
          let
            above = 65536 - containerUID - 1;
          in
          [
            "--uidmap=0:1:${toString containerUID}"
            "--uidmap=${toString containerUID}:0:1"
            "--uidmap=${toString (containerUID + 1)}:${toString (containerUID + 1)}:${toString above}"
            "--gidmap=0:1:${toString containerGID}"
            "--gidmap=${toString containerGID}:0:1"
            "--gidmap=${toString (containerGID + 1)}:${toString (containerGID + 1)}:${toString above}"
          ];
      in
      mkRootlessPodmanService {
        inherit pkgs;
        name = appName;
        podTraceSyscalls = cfg.podTraceSyscalls;
        systemdTraceSyscalls = cfg.systemdTraceSyscalls;
        image = "${appImage}:${appPinnedVersion}";
        subUidStart = 100000 + config.homelab.portRegistry.${appName}.appId * 65536;
        ports = [ "127.0.0.1:${toString listenHttpPort}:80" ];
        volumes = [ "${appPath}/config:/config" ];

        environment = {
          PUID = "1000";
          PGID = "1000";
        }
        // lib.optionalAttrs (config.time.timeZone != null) {
          TZ = config.time.timeZone;
        };
        extraOptions = uidmapOptions ++ [
          "--add-host=${cfg.authDomain}:host-gateway"
          "--cap-drop=ALL"
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
          "--cap-add=NET_BIND_SERVICE"
          "--cap-add=FOWNER"
        ];
        extraServiceConfig = {
          RemoveIPC = true;
          LockPersonality = true;
          RestrictRealtime = true;
          ProtectClock = true;
          UMask = "0077";
          RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
          CapabilityBoundingSet = "~CAP_SYS_MODULE CAP_SYS_PACCT CAP_SYS_BOOT CAP_SYS_TTY_CONFIG CAP_SYS_RAWIO CAP_SYS_PTRACE CAP_SYS_NICE CAP_SYS_RESOURCE CAP_SYS_CHROOT CAP_BLOCK_SUSPEND CAP_LEASE CAP_LINUX_IMMUTABLE CAP_IPC_LOCK CAP_BPF CAP_MAC_ADMIN CAP_MAC_OVERRIDE CAP_AUDIT_WRITE CAP_AUDIT_CONTROL CAP_AUDIT_READ CAP_SYSLOG CAP_NET_ADMIN CAP_NET_BROADCAST CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_KILL CAP_MKNOD CAP_CHOWN CAP_FSETID CAP_SETFCAP CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE CAP_FOWNER CAP_IPC_OWNER";
          SystemCallFilter = "~@reboot @swap @obsolete @cpu-emulation @debug @raw-io @module @clock";
          ProtectSystem = "strict";
          ReadWritePaths = [
            "/run/pod-dokuwiki"
            "/var/lib/pod-containers/pod-dokuwiki"
            appPath
          ];
          ProtectHome = true;
          PrivateTmp = true;
          ProtectProc = "invisible";
        };
      }
    ))
  ];
}
