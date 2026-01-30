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
  appName = "radio";
  appDisplayName = "Radio";
  appCategory = "Essentials";
  appIcon = "https://radio.0cx.de/static/parrot.gif";
  appPlatform = "nixos";

  cfg = config.homelab.features.${appName};

  appDescription = cfg.package.meta.description or "Internet Radio";
  appUrl = cfg.package.meta.homepage or "https://github.com/pinpox/radio";
  appPinnedVersion = cfg.package.version or "unknown";

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;

  exposedURL = "https://${cfg.serviceDomain}";
  internalURL = "http://127.0.0.1:${toString listenHttpPort}";

  stationFile = pkgs.writeText "stations.ini" (
    lib.concatMapStringsSep "\n\n" (station: ''
      [${station.name}]
      url = ${station.url}
    '') cfg.stations
  );

in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      package = mkOption {
        type = types.package;
        default = pkgs.radio;
        defaultText = literalExpression "pkgs.radio";
        description = "The radio package to use";
      };

      stations = mkOption {
        description = ''
          Radio station list (order preserved).
          Radio station settings. See <https://github.com/pinpox/radio/blob/main/stations.ini>
        '';
        default = [
          {
            name = "Hirschmilch Psytrance";
            url = "https://hirschmilch.de:7000/psytrance.mp3";
          }
          {
            name = "Hirschmilch Progressive";
            url = "https://hirschmilch.de:7000/progressive.mp3";
          }
        ];
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the radio station";
              };
              url = mkOption {
                type = types.str;
                description = "Stream URL for the radio station";
              };
            };
          }
        );
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
          };

        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

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

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
          "@service-${appName}-config" =
            "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
        };

        # Enable radio service
        systemd.services.${appName} = {
          description = "Radio stream";
          wants = [
            "network-online.target"
          ];
          wantedBy = [
            "multi-user.target"
          ];

          environment = {
            RADIO_ADDRESS = "127.0.0.1:${toString listenHttpPort}";
            RADIO_STATIONFILE = "${stationFile}";
          };

          serviceConfig = {
            DynamicUser = true;
            ExecStart = "${lib.getExe cfg.package}";
            LockPersonality = true;
            LogsDirectory = appName;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            NonBlocking = true;
            PrivateDevices = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            Restart = "on-failure";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RuntimeDirectory = appName;
            StateDirectory = appName;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "@chown"
              "~@aio"
              "~@keyring"
              "~@memlock"
              "~@setuid"
              "~@timer"
            ];
          };
        };

        # Enable radio in TLS mode with nginx reverse proxy if openFirewall is enabled
        security.acme.acceptTerms = mkIf cfg.openFirewall true;
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
                # add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;
                add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://unpkg.com; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https: ws: wss:;" always;

                # Modern CORS headers
                add_header Cross-Origin-Opener-Policy "same-origin-allow-popups" always;
                add_header Cross-Origin-Resource-Policy "cross-origin" always;
                add_header Cross-Origin-Embedder-Policy "unsafe-none" always;

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
