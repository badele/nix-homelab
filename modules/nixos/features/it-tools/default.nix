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

  appName = "it-tools";
  appCategory = "Essentials";
  appDisplayName = "it-tools";
  appIcon = "it-tools";
  appPlatform = "podman";
  appDescription = "Collection of handy online tools for developers, with great UX";
  appUrl = "https://github.com/sharevb/it-tools";
  appImage = "ghcr.io/sharevb/it-tools";
  appPinnedVersion = "2025.10.12";

  cfg = config.homelab.features.${appName};

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

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
      openTailscale = mkEnableOption "Open firewall ports for tailscale (incoming)";
      podTraceSyscalls = mkEnableOption "Wrap podman run with strace (startup+runtime, no --uidmap; output: /tmp/it-tools-strace.log on service stop)";
      systemdTraceSyscalls = mkEnableOption "Attach strace to running podman via systemd ExecStartPost as root (runtime only, all images; output: /tmp/it-tools-strace.log on service stop)";
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
          description = "${appDescription} [${cfg.serviceDomain}]";
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
      networking.firewall.interfaces = mkFirewallInterfaces cfg [
        443
      ];

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
              Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; media-src 'self' blob:  https:; connect-src 'self' https:;";

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

    })

    (mkIf cfg.enable (mkRootlessPodmanService {
      inherit pkgs;
      name = appName;
      podTraceSyscalls = cfg.podTraceSyscalls;
      systemdTraceSyscalls = cfg.systemdTraceSyscalls;
      image = "${appImage}:${appPinnedVersion}";
      subUidStart = 100000 + config.homelab.portRegistry.${appName}.appId * 65536;
      ports = [ "127.0.0.1:${toString listenHttpPort}:8080" ];
      environment = lib.optionalAttrs (config.time.timeZone != null) {
        TZ = config.time.timeZone;
      };
      extraOptions = [
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
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
          "/run/pod-it-tools"
          "/var/lib/pod-containers/pod-it-tools"
        ];
        ProtectHome = true;
        PrivateTmp = true;
        ProtectProc = "invisible";
      };
    }))
  ];
}
