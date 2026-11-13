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
  appSubDomain = head (splitString "." cfg.serviceDomain);

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  # linkding runs as www-data (uid/gid 33) inside the container.
  # Remap uid/gid 33 → 0 (pod-linkding on host) so volume files are owned by pod-linkding.
  containerUID = 33;
  containerGID = 33;
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
      podTraceSyscalls = mkEnableOption "Wrap podman run with strace (startup+runtime, no --uidmap; output: /tmp/linkding-strace.log on service stop)";
      systemdTraceSyscalls = mkEnableOption "Attach strace to running podman via systemd ExecStartPost as root (runtime only, all images; output: /tmp/linkding-strace.log on service stop)";
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
          siteMonitor = "${monitoringURL}/bookmarks/shared";
        };

        gatus = mkIf config.services.gatus.enable {
          name = appDisplayName;
          url = "${monitoringURL}/bookmarks/shared";
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
          ADMINPASSWORD="$(pwgen -s 16 1)"

          cat > "$out/envfile" << EOF
          LD_SUPERUSER_NAME=bookadmin
          LD_SUPERUSER_PASSWORD=$ADMINPASSWORD
          EOF
        '';
      };

      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0751 root root -"
        "d ${appPath}/data 0750 pod-${appName} pod-${appName} -"

        # Backup directory
        "d /var/backup/${appName} 0750 root root -"
      ];

      # Open firewall ports if openFirewall is enabled
      networking.firewall.interfaces = mkFirewallInterfaces cfg [
        443
      ];

      # Add domain alias
      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service alias
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
              Content-Security-Policy "default-src 'self'; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https:;"

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

          service_status=$(systemctl is-active pod-${appName})
          if [ "$service_status" = "active" ]; then
            systemctl stop pod-${appName}
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/linkding/
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

            # Backup current linkding data locally
            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            # Restore from borgbackup
            rsync -avH --delete --numeric-ids /var/backup/linkding/ "${appPath}/"

            systemctl start pod-${appName}
          fi
        '';
      };

    })

    # Rootless podman service under pod-linkding system user
    (mkIf cfg.enable (mkRootlessPodmanService {
      inherit pkgs;
      name = appName;
      podTraceSyscalls = cfg.podTraceSyscalls;
      systemdTraceSyscalls = cfg.systemdTraceSyscalls;
      image = "${appImage}:${appPinnedVersion}";
      subUidStart = 100000 + config.homelab.portRegistry.${appName}.appId * 65536;
      ports = [ "127.0.0.1:${toString listenHttpPort}:9090" ];
      volumes = [ "${appPath}/data:/etc/linkding/data" ];

      credentials = [
        {
          id = "envfile";
          path = config.clan.core.vars.generators."linkding".files."envfile".path;
        }
      ];
      environment = {
        LD_ENABLE_OIDC = "true";
        OIDC_USE_PKCE = "true";
        OIDC_RP_CLIENT_ID = "371338396787867649";
        OIDC_OP_AUTHORIZATION_ENDPOINT = "https://${authdomain}/oauth/v2/authorize";
        OIDC_OP_TOKEN_ENDPOINT = "https://${authdomain}/oauth/v2/token";
        OIDC_OP_USER_ENDPOINT = "https://${authdomain}/oidc/v1/userinfo";
        OIDC_OP_JWKS_ENDPOINT = "https://${authdomain}/oauth/v2/keys";
      }
      // lib.optionalAttrs (config.time.timeZone != null) {
        TZ = config.time.timeZone;
      };
      extraOptions = uidmapOptions ++ [
        "--add-host=${authdomain}:host-gateway"
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=NET_BIND_SERVICE"
      ];
      extraServiceConfig = {
        RemoveIPC = true;
        LockPersonality = true;
        RestrictRealtime = true;
        ProtectClock = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
        CapabilityBoundingSet = "~CAP_SYS_MODULE CAP_SYS_PACCT CAP_SYS_BOOT CAP_SYS_TTY_CONFIG CAP_SYS_RAWIO CAP_SYS_PTRACE CAP_SYS_NICE CAP_SYS_RESOURCE CAP_SYS_CHROOT CAP_BLOCK_SUSPEND CAP_LEASE CAP_LINUX_IMMUTABLE CAP_IPC_LOCK CAP_BPF CAP_MAC_ADMIN CAP_MAC_OVERRIDE CAP_AUDIT_WRITE CAP_AUDIT_CONTROL CAP_AUDIT_READ CAP_SYSLOG CAP_NET_ADMIN CAP_NET_BROADCAST CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_KILL CAP_MKNOD CAP_CHOWN CAP_FSETID CAP_SETFCAP CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE CAP_FOWNER CAP_IPC_OWNER";
        SystemCallFilter = "~@reboot @swap @obsolete @cpu-emulation @debug @raw-io @module @clock";
        MemoryDenyWriteExecute = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/run/pod-linkding"
          "/var/lib/pod-containers/pod-linkding"
          appPath
        ];
        ProtectHome = true;
        PrivateTmp = true;
        ProtectProc = "invisible";
      };
    }))
  ];
}
