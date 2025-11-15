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
  appName = "grafana";
  appCategory = "System Health";
  appDisplayName = "Grafana";
  appIcon = "grafana";
  appPlatform = "nixos";
  appUrl = pkgs.${appName}.meta.homepage;
  appDescription = "${pkgs.${appName}.meta.description}";
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  # Get port from central registry
  listenHttpPort = config.homelab.portRegistry.${appName}.httpPort;

  # Service URL: use nginx domain if firewall is open, otherwise use direct IP:port
  serviceURL =
    if cfg.openFirewall then
      "https://${cfg.serviceDomain}"
    else
      "http://127.0.0.1:${toString listenHttpPort}";

in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = lib.mkEnableOption appName;

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = lib.mkMerge [
    {
      homelab.features.${appName} = {
        appInfos = {
          category = appCategory;
          displayName = appDisplayName;
          icon = appIcon;
          platform = appPlatform;
          url = appUrl;
          description = appDescription;
          pinnedVersion = appPinnedVersion;
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      homelab.features.${appName} = {
        homepage = mkIf cfg.enable {
          icon = appIcon;
          href = serviceURL;
          description = appDescription;
          siteMonitor = serviceURL;
        };

        gatus = mkIf cfg.enable {
          name = appDisplayName;
          url = "${serviceURL}/api/health";
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY].database == ok"
            "[RESPONSE_TIME] < 50"
          ];
        };
      };

      clan.core.vars.generators.${appName} = {
        files.admin_password = {
          owner = "grafana";
          group = "grafana";
          mode = "0400";
        };
        files.secret_key = {
          owner = "grafana";
          group = "grafana";
          mode = "0400";
        };

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
          pkgs.gnugrep
          pkgs.gawk
        ];

        script = ''
          # CLIENTSECRET="$(pwgen -s 48 1)"
          # DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";

          ADMINPASSWORD="$(pwgen -s 48 1)"
          SECRETKEY="$(pwgen -s 48 1)"

          # echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
          # echo "$DIGETSECRET" > "$out/digest-client-secret"

          echo "$ADMINPASSWORD" > "$out/admin_password"
          echo "$SECRETKEY" > "$out/secret_key"
        '';
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        443
      ];

      homelab.alias = [ "${cfg.serviceDomain}" ];
      programs.bash.shellAliases = (mkServiceAliases appName) // {
        "@service-${appName}-config" =
          "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
      };

      services.grafana = {
        enable = true;
        provision.enable = true;

        settings = {
          server = {
            http_port = listenHttpPort;
            http_addr = "127.0.0.1";
            domain = cfg.serviceDomain;
            root_url = "https://${cfg.serviceDomain}";
            protocol = "http";
          };

          users = {
            allow_signup = false;
          };
          # TODO: enable anonymous access from NixOS option
          "auth.anonymous" = {
            enabled = true;
            org_name = "ma cabane";
            org_role = "Viewer";
            hide_version = true;
          };
          security = {
            cookie_secure = true;
            admin_password = "$__file{${
              config.clan.core.vars.generators."grafana".files."admin_password".path
            }}";
            secret_key = "$__file{${config.clan.core.vars.generators."grafana".files."secret_key".path}}";
          };

          analytics = {
            reporting_enabled = false;
            check_for_updates = false;
          };

        };
      };

      services.nginx.virtualHosts = lib.mkIf cfg.openFirewall {
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
