{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  appName = "blocky";
  appDisplayName = "Blocky";
  appCategory = "Core Services";
  appIcon = "blocky";
  appPlatform = "nixos";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};
  availableInterfaces = attrNames config.networking.interfaces;
  listenDnsAddresses = resolveListenInterfaceAddresses appName cfg.listenInterfaces;
  listenDnsPorts = map (address: "${address}:53") listenDnsAddresses;

  sharedDomainEntries = flatten (map attrValues (attrValues config.homelab.domains.sharedEntries));
  matchingDomainEntries = filter (
    entry:
    entry.enabled
    && entry.targetAddress != null
    && any (scope: elem scope cfg.dnsRegistrationScopes) entry.registerScope
  ) sharedDomainEntries;

  matchingDomainAddresses = foldl' (
    acc: entry:
    acc
    // {
      ${entry.domain} = lib.unique ((acc.${entry.domain} or [ ]) ++ [ entry.targetAddress ]);
    }
  ) { } matchingDomainEntries;

  listenHttpPort = 10000 + config.homelab.portRegistry.${appName}.appId;
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

      settings = mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = import ./settings.nix { inherit config lib appName; };
        description = ''
          ${appDisplayName} configuration. Refer to
          <https://0xerr0r.github.io/blocky/configuration/>
          for details on supported values.
        '';
      };

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      enableMetrics = mkEnableOption "Expose Blocky metrics";
      openFirewall = mkEnableOption "Open firewall ports (incoming)";
      openTailscale = mkEnableOption "Open firewall ports for tailscale (incoming)";

      dnsRegistrationScopes = mkOption {
        type = listOf str;
        default = [ ];
        description = "DNS registration scopes published by Blocky custom DNS.";
      };
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
      assertions = [
        {
          assertion = cfg.listenInterfaces != [ ];
          message =
            "homelab.features.blocky.listenInterfaces must be set to expose Blocky DNS listeners explicitly. "
            + "Available interfaces: "
            + (
              if availableInterfaces == [ ] then
                "<none>"
              else
                concatStringsSep ", " availableInterfaces
            );
        }
      ];

      homelab.features.${appName}.settings = mkMerge [
        (import ./settings.nix)

        (mkIf cfg.enableMetrics {
          prometheus.enable = true;
        })

        (mkIf (matchingDomainEntries != [ ]) {
          customDNS =
            let
              aliasMapping = mapAttrs (_: addresses: concatStringsSep "," addresses) matchingDomainAddresses;
            in
            {
              customTTL = "1h";
              filterUnmappedTypes = true;
              mapping = aliasMapping;
            };
        })

        {
          ports = {
            dns = listenDnsPorts;
            http = listenHttpPort;
          };
        }
      ];

      networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [ 53 ];
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        53
        443
      ];

      homelab.alias = [ cfg.serviceDomain ];

      programs.bash.shellAliases = (mkServiceAliases appName) // {
        "@service-${appName}-config" =
          "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
      };

      services.${appName} = {
        enable = true;
        settings = cfg.settings;
      };

      security.acme.acceptTerms = mkIf cfg.openFirewall true;

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
              Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;"

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

      ############################################################################
      # Integration
      ############################################################################
      homelab.integrations.services.${appName} = mkDefault {
        displayName = appDisplayName;
        category = appCategory;
        icon = appIcon;
        description = appDescription;

        homepage = {
          href = exposedURL;
          description = "${appDescription} [${cfg.serviceDomain}]";
          siteMonitor = internalURL;
        };

        gatus = {
          url = internalURL;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY] == pat(*Version ${appPinnedVersion}*)"
          ];
          ui.hide-hostname = true;
        };

        victoriametrics = mkIf cfg.enableMetrics {
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString listenHttpPort}" ];
              labels = {
                instance = config.networking.hostName;
                hostname = cfg.serviceDomain;
              };
            }
          ];
        };

        grafana = mkIf cfg.enableMetrics {
          dashboards = [
            {
              name = appName;
              orgId = 1;
              type = "file";
              disableDeletion = true;
              options.path =
                let
                  dashboardContent = builtins.readFile ./grafana_dashboard.json;
                  customizedDashboard =
                    builtins.replaceStrings [ "BLOCKY_URL_CONTENT" ] [ cfg.serviceDomain ]
                      dashboardContent;
                in
                "${pkgs.writeTextDir "${appName}-dashboard.json" customizedDashboard}/${appName}-dashboard.json";
            }
          ];
        };
      };

    })
  ];
}
