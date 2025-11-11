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

      # these external DNS resolvers will be used. Blocky picks 2 random resolvers from the list for each query
      # format for resolver: [net:]host:[port][/path]. net could be empty (default, shortcut for tcp+udp), tcp+udp, tcp, udp, tcp-tls or https (DoH). If port is empty, default port will be used (53 for udp and tcp, 853 for tcp-tls, 443 for https (Doh))
      # this configuration is mandatory, please define at least one external DNS resolver
      #
      # https://www.privacyguides.org/en/dns
      # https://dnsprivacy.org/public_resolvers
      # https://www.joindns4.eu/for-public
      # upstreams = mkOption {
      #   type = attrs;
      #   default = {
      #     groups = {
      #       default = [
      #         "9.9.9.9"
      #         "149.112.112.112"
      #         "https://dns.quad9.net/dns-query"
      #         "tcp-tls:dns.quad9.net"
      #       ];
      #     };
      #   };
      #   description = ''
      #     Upstream DNS resolvers configuration.
      #     Format: { groups = { <group-name> = [ "resolver1" "resolver2" ... ]; }; }
      #     See: https://0xerr0r.github.io/blocky/configuration/#upstreams
      #   '';
      # };

      # denylists = mkOption {
      #   type = attrs;
      #   default = {
      #     ads = [
      #       "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
      #       "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
      #     ];
      #     fakenews = [
      #       "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-only/hosts"
      #     ];
      #     gambling = [
      #       "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-only/hosts"
      #     ];
      #     adult = [
      #       "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"
      #     ];
      #   };
      #   description = ''
      #     Blocklists configuration.
      #     Format: { <list-name> = [ "url1" "url2" ... ]; }
      #     See: https://0xerr0r.github.io/blocky/configuration/#blocking
      #   '';
      # };

      # clientGroupsBlock = mkOption {
      #   type = attrs;
      #   default = {
      #     default = [
      #       "ads"
      #       "fakenews"
      #       "gambling"
      #       "adult"
      #     ];
      #   };
      #   description = ''
      #     Client groups blocking configuration.
      #     Format: { <client-group> = [ "list1" "list2" ... ]; }
      #     See: https://0xerr0r.github.io/blocky/configuration/#blocking
      #   '';
      # };

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

        # Monitoring section
        # homelab.features.grafana = lib.mkIf cfg.enableMonitoring {
        #   dashboards = [ ./grafana_dashboard.json ];
        # };
        #
        # homelab.features.prometheus.settings = lib.mkIf cfg.enablePrometheusExport {
        #   scrape_configs = [
        #     {
        #       job_name = "blocky";
        #       honor_timestamps = true;
        #       metrics_path = "/metrics";
        #       scheme = "http";
        #       static_configs = [ { targets = [ (appName + ":443") ]; } ];
        #     }
        #   ];
        # };

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
