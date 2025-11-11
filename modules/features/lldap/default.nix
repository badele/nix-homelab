{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
}:
let
  appName = "lldap";
  cfg = config.homelab.features.${appName};
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  containerUid = 1000;
  containerGid = 1000;

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUid;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGid;
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} =
    with lib;
    with types;
    mkFeatureOptions {
      extraOptions = {

        serviceDomain = mkOption {
          type = str;
          default = "${appName}.${config.homelab.domain}";
          description = "${appName} service domain name";
        };

        ldapDomain = mkOption {
          type = str;
          default = "dc=homelab,dc=lan";
          description = "Base DN for the LDAP directory";
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
          category = "Core Services";
          displayName = "LLDAP";
          description = "Lightweight LDAP server for managing users and groups.";
          platform = "podman";
          icon = "lldap";
          url = "https://github.com/lldap/lldap";
          image = "lldap/lldap";
          version = "2025-09-28-alpine";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        3890
        17170
      ];

      clan.core.vars.generators.lldap = {
        files.jwt-secret = { };
        files.password = { };
        files.envfile = { };

        runtimeInputs = [
          pkgs.pwgen
        ];

        script = ''
          pwgen -s 32 1 > "$out/jwt-secret"
          pwgen -s 16 1 > "$out/password"

          KEYSEED="$(pwgen -s 32 1)"
          cat > "$out/envfile" << EOF
          LLDAP_KEY_SEED=$KEYSEED
          EOF
        '';
      };

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
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."jwt-secret".path
          } 
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."password".path
          }
        '';
      };

      # Add Podman management aliases
      programs.bash.shellAliases = mkPodmanAliases appName;

      virtualisation.oci-containers.containers.${appName} = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        ports = [
          "${ip}:3890:3890"
          "127.0.0.1:${toString listenPort}:17170"
        ];

        volumes = [
          "${appPath}/data:/data"
          "${config.clan.core.vars.generators.${appName}.files."jwt-secret".path}:/run/secrets/jwt-secret:ro"
          "${config.clan.core.vars.generators.${appName}.files."password".path}:/run/secrets/password:ro"
        ];

        environmentFiles = [
          config.clan.core.vars.generators.${appName}.files."envfile".path
        ];

        environment = {
          LLDAP_LDAP_BASE_DN = cfg.ldapDomain;
          LLDAP_JWT_SECRET_FILE = "/run/secrets/jwt-secret";
          LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/password";
        };

        extraOptions = [
          "--cap-drop=ALL"

          # for nginx
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
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
              add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;

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

      #############################################################################
      # Backup
      #############################################################################
      clan.core.state.lldap = {
        folders = [ appPath ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              config.systemd.package
              pkgs.coreutils
              pkgs.rsync
            ]
          }

          service_status=$(systemctl is-active lldap-launcher)
          if [ "$service_status" = "active" ]; then
            systemctl stop lldap-launcher
            rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/lldap/
            systemctl start lldap-launcher
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

          service_status="$(systemctl is-active lldap-launcher)"

          if [ "$service_status" = "active" ]; then
            systemctl stop lldap-launcher

            # Backup current lldap data locally
            DATE=$(date +%Y%m%d-%H%M%S)
            cp -rp "${appPath}" "${appPath}.$DATE.bak"

            # Restore from borgbackup
            rsync -avH --delete --numeric-ids /var/backup/lldap/ "${appPath}/"

            # Fix permissions after restore
            chown -R ${appName}:${appName} "${appPath}"

            systemctl start lldap-launcher
          fi
        '';
      };
    })
  ];
}
