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
  appName = "blocky";
  cfg = config.homelab.features.${appName};
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;

  yaml = pkgs.formats.yaml { };
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      settings = mkOption {
        type = yaml.type;
        apply = yaml.generate "config.yml";
        default = import ./settings.nix { inherit config lib appName; };
        description = ''
          Blocky configuration. Refer to
          <https://0xerr0r.github.io/blocky/configuration/>
          for details on supported values.
        '';
      };

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
      enableMonitoring = mkEnableOption "Enable monitoring features";
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
            category = "Core Services";
            displayName = "Blocky";
            description = "Fast and lightweight DNS proxy as ad-blocker";
            platform = "podman";
            icon = "blocky";
            url = "https://0xerr0r.github.io/blocky/";
            image = "ghcr.io/0xerr0r/blocky";
            version = "v0.27.0";
          };
        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

        # blocky section
        homelab.features.${appName}.settings = mkMerge [
          # Default configuration
          (import ./settings.nix)

          # monitoring settings
          (mkIf cfg.enableMonitoring {
            prometheus.enable = true;
          })

          # Alias
          (mkIf (config.homelab.alias != [ ]) {
            customDNS =
              let
                aliasMapping = listToAttrs (
                  map (alias: {
                    name = alias;
                    value = config.homelab.host.address;
                  }) config.homelab.alias
                );
              in
              {
                customTTL = "1h";
                filterUnmappedTypes = true;
                mapping = aliasMapping;
              };
          })
        ];

        networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [
          53
        ];
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          53
          443
        ];

        # Add Podman management aliases
        programs.bash.shellAliases = mkPodmanAliases appName;

        virtualisation.oci-containers.containers.${appName} = {
          image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

          ports = [
            "${ip}:53:53/udp"
            "${ip}:53:53/tcp"
            "127.0.0.1:${toString listenPort}:4000"
          ];

          volumes = [
            "${cfg.settings}:/app/config.yml"
          ];

          extraOptions = [
            "--cap-drop=ALL"

            # for nginx
            "--cap-add=CHOWN"
            "--cap-add=SETUID"
            "--cap-add=SETGID"
            "--cap-add=DAC_OVERRIDE"
            "--cap-add=NET_BIND_SERVICE"
            "--subuidname=root"
            "--subgidname=root"
          ];
        };
        # // cfg.containerInfos;

        homelab.alias = mkIf cfg.openFirewall [ "${cfg.serviceDomain}" ];

        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            forceSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString listenPort}";
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
                add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;

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
