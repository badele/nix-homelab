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
  appName = "goaccess";
  appCategory = "Core Services";
  appDisplayName = "GoAccess";
  appIcon = "goaccess";
  appPlatform = "nixos";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;
  appServiceURL = serviceURL;

  cfg = config.homelab.features.${appName};

  listenHttpPort = config.homelab.portRegistry.${appName}.httpPort;

  # Service URL: use nginx domain if firewall is open, otherwise use direct IP:port
  serviceURL =
    if cfg.openFirewall then
      "https://${cfg.serviceDomain}"
    else
      "http://127.0.0.1:${toString listenHttpPort}";

  priv_goaccess = "/var/lib/goaccess";
  pub_goaccess = "/var/www/goaccess";

  user-agent-list = pkgs.writeText "browsers.list" ''
    # List of browsers and their categories
    # e.g., WORD delimited by tab(s) \t TYPE
    # TYPE can be any type and it's not limited to the ones below.
  '';
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
            serviceURL = appServiceURL;
          };

        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

        #######################################################################
        # Monitoring
        #######################################################################

        homelab.features.${appName} = {
          homepage = mkIf cfg.enable {
            icon = appIcon;
            href = serviceURL;
            description = appDescription;
            siteMonitor = appServiceURL;
          };

          gatus = mkIf cfg.enable {
            name = appDisplayName;
            url = serviceURL;
            group = appCategory;
            type = "HTTP";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
              ''[BODY] == pat(*"version": "${appPinnedVersion}"*)''
            ];
          };

        };

        #######################################################################
        # Service
        #######################################################################

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        programs.bash.shellAliases = (mkServiceAliases appName) // {
        };

        users.users.goaccess = {
          isSystemUser = true;
          group = "nginx";
          createHome = true;
          home = "${pub_goaccess}";
          homeMode = "0774";
        };

        services.nginx.commonHttpConfig = ''
          log_format vcombined '$host:$server_port $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referrer" "$http_user_agent"';
          access_log /var/log/nginx/private.log vcombined;
        '';

        systemd.tmpfiles.rules = [
          "d ${priv_goaccess} 0755 goaccess nginx -"
          "d ${priv_goaccess}/db 0755 goaccess nginx -"
          "d ${pub_goaccess} 0755 goaccess nginx -"
        ];

        systemd.services.goaccess = {
          description = "GoAccess server monitoring";
          preStart = ''
            rm -f ${pub_goaccess}/index.html
          '';
          serviceConfig = {
            User = "goaccess";
            Group = "nginx";
            ExecStart = ''
              ${pkgs.goaccess}/bin/goaccess \
                -f /var/log/nginx/public.log \
                --log-format=VCOMBINED \
                --browsers-file=${user-agent-list} \
                --real-time-html \
                --all-static-files \
                --html-refresh=30 \
                --persist \
                --restore \
                --db-path=${priv_goaccess}/db \
                --no-query-string \
                --unknowns-log=${priv_goaccess}/unknowns.log \
                --invalid-requests=${priv_goaccess}/invalid-requests.log \
                --anonymize-ip \
                --ws-url=wss://${cfg.serviceDomain}:443/ws \
                --port=${toString listenHttpPort} \
                -o "${pub_goaccess}/index.html"
            '';
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Type = "simple";
            Restart = "on-failure";
            RestartSec = "10s";

            # hardening
            WorkingDirectory = "${pub_goaccess}";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = "read-only";
            ProtectSystem = "strict";
            SystemCallFilter = "~@clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @privileged @reboot @resources @setuid @swap @raw-io";
            ReadOnlyPaths = "/";
            ReadWritePaths = [
              "/proc/self"
              "${pub_goaccess}"
              "${priv_goaccess}"
            ];
            PrivateDevices = "yes";
            ProtectKernelModules = "yes";
            ProtectKernelTunables = "yes";
          };
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
        };

        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {
            addSSL = true;
            enableACME = true;
            root = "${pub_goaccess}";

            locations."/ws" = {
              proxyPass = "http://127.0.0.1:${toString listenHttpPort}";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_buffering off;
                proxy_read_timeout 7d;
              '';
            };
            extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
          };
        };

      })
    ];
}
