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
  appName = "victoriametrics";
  cfg = config.homelab.features.${appName};
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  containerUid = 0; # root
  containerGid = 0; # root

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUid;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGid;

in
{
  imports = [

    ./vmagent.nix
  ];
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {

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
    # Always set appInfos, even when disabled
    {
      homelab.features.${appName} = {
        appInfos = {
          category = "System Health";
          displayName = "Victoriametrics Server";
          description = "Simple, Reliable, Efficient Monitoring.";
          platform = "podman";
          icon = "victoriametrics";
          url = "https://victoriametrics.com";
          image = "victoriametrics/victoria-metrics";
          version = "v1.129.1";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        443
      ];

      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0750 root root -"
        "d ${appPath}/data 0750 root root -"

        # Backup directory
        "d /var/backup/lldap 0750 root root -"
      ];

      # Update secrets permissions before starting the container
      systemd.services."podman-${appName}" = {
        preStart = lib.mkAfter ''
          chown ${toString hostUid}:${toString hostGid} ${appPath}/data 
        '';
      };

      # Add Podman management aliases
      programs.bash.shellAliases = mkPodmanAliases appName;

      # victoria-metrics
      virtualisation.oci-containers.containers.${appName} = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        cmd = [
          "-storageDataPath=/data/victoriametrics"
          "-retentionPeriod=100y"
          "-selfScrapeInterval=5s"
        ];

        ports = [
          "127.0.0.1:${toString listenPort}:8428"
        ];

        volumes = [
          "${appPath}/data:/data/victoriametrics"
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
