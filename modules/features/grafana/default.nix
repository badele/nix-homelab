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
  appName = "grafana";
  cfg = config.homelab.features.${appName};
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;

  ini = pkgs.formats.ini { };

  containerUid = 472; # grafana
  containerGid = 0; # root

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUid;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGid;

in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = lib.mkEnableOption appName;

      settings = lib.mkOption {
        type = ini.type;
        default = { };
        apply = ini.generate "grafana.ini";
        description = ''
          Grafana settings. See <https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/>
          for available options. INI format is used.
        '';
      };

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      createAdminAccount = mkOption {
        type = bool;
        default = true;
        description = ''
          Create admin account with random password, use clan vars get <machine> grafana/admin_password
        '';
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
          category = "System Health";
          displayName = "Grafana";
          description = "Monitoring and observability, providing powerful tools for visualizing and analyzing metrics.";
          platform = "podman";
          icon = "grafana";
          url = "https://github.com/grafana/grafana";
          image = "grafana/grafana";
          version = "12.2.1";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      clan.core.vars.generators.${appName} = lib.mkIf cfg.createAdminAccount {
        # files.oauth2-client-secret = {
        #   owner = "grafana";
        #   group = "grafana";
        #   mode = "0400";
        # };
        # files.digest-client-secret = {
        #   owner = "grafana";
        #   group = "grafana";
        #   mode = "0400";
        # };

        files.admin_password = { };
        files.secret_key = { };

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

      # Grafana settings
      homelab.features.${appName}.settings = lib.mkIf cfg.createAdminAccount {
        security = {
          cookie_secure = true;
          admin_password = "$__file{${
            config.clan.core.vars.generators.${appName}.files.admin_password.path
          }}";
          secret_key = "$__file{${config.clan.core.vars.generators.${appName}.files.secret_key.path}}";
        };
      };

      networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [
        53
      ];
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        53
        443
      ];

      # Update secrets permissions before starting the container
      systemd.services."podman-${appName}" = {
        preStart = lib.mkAfter ''
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."admin_password".path
          } 
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."secret_key".path
          }
        '';
      };

      # Add Podman management aliases
      programs.bash.shellAliases = mkPodmanAliases appName;

      virtualisation.oci-containers.containers.${appName} = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        ports = [
          "127.0.0.1:${toString listenPort}:3000"
        ];

        volumes = [
          "${cfg.settings}:/etc/grafana/grafana.ini"

          "${config.clan.core.vars.generators.${appName}.files.admin_password.path}:${
            config.clan.core.vars.generators.${appName}.files.admin_password.path
          }"

          "${config.clan.core.vars.generators.${appName}.files.secret_key.path}:${
            config.clan.core.vars.generators.${appName}.files.secret_key.path
          }"
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

      homelab.alias = lib.mkIf cfg.openFirewall [ "${cfg.serviceDomain}" ];

      services.nginx.virtualHosts = lib.mkIf cfg.openFirewall {
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
