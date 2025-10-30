{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "radio.${domain}";

  version = "1.0.6";
  appPath = "/data/podman/pawtunes";
  appId = 8;

  listenPort = 10000 + appId;
  subIdRangeStart = (100 + appId) * 100000;
  appUser = "pawtunes";
  appGroup = "pawtunes";
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [ 443 ];

  ############################################################################
  # Rootless podman user
  ############################################################################
  users = {
    users.${appUser} = {
      isSystemUser = true;
      group = appGroup;
      home = "/var/lib/podman/users/${appUser}";
      createHome = true;
      subUidRanges = [
        {
          startUid = subIdRangeStart;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = subIdRangeStart;
          count = 65536;
        }
      ];
    };
    groups.${appGroup} = { };
  };

  ############################################################################
  # Service configuration
  ############################################################################

  systemd.tmpfiles.rules = [
    # Enable linger for pawtunes user
    "f /var/lib/systemd/linger/${appUser} 0644 root root - -"

    # Application data
    "d ${appPath} 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/data 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/data/cache 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/inc 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/inc/config 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/inc/locale 0750 ${appUser} ${appGroup} -"

    # Backup directory
    "d /var/backup/pawtunes 0750 ${appUser} ${appGroup} -"
  ];

  systemd.services.pawtunes = {
    description = "Pawtunes radio streaming service (rootless podman)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    # Required to make `newuidmap` available to the systemd service
    path = [
      "/run/wrappers"
      pkgs.podman
    ];

    serviceConfig = {
      Type = "simple";
      User = appUser;
      Group = appGroup;

      # Restart policy
      Restart = "on-failure";
      RestartSec = "30s";
      TimeoutStartSec = 120;
      TimeoutStopSec = 120;

      ExecStartPre = [
        # Pull the image if needed
        "${pkgs.podman}/bin/podman pull jackyprahec/pawtunes:${version}"
        # Remove existing container if it exists
        "-${pkgs.podman}/bin/podman rm -f pawtunes"
      ];

      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
          --rm \
          --name=pawtunes \
          -p 127.0.0.1:${toString listenPort}:80 \
          -v ${appPath}/inc/config:/var/www/html/inc/config \
          -v ${appPath}/inc/locale:/var/www/html/inc/locale \
          -v ${appPath}/data:/var/www/html/data \
          --cap-drop=ALL \
          --cap-add=CHOWN \
          --cap-add=SETUID \
          --cap-add=SETGID \
          --cap-add=DAC_OVERRIDE \
          --cap-add=NET_BIND_SERVICE \
          --userns=keep-id:uid=33,gid=33 \
          --cgroup-manager=cgroupfs \
          jackyprahec/pawtunes:${version}
      '';

      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 pawtunes";
      ExecStopPost = "-${pkgs.podman}/bin/podman rm -f pawtunes";
    };
  };

  services.nginx.virtualHosts."${appDomain}" = {
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
        add_header Content-Security-Policy "default-src 'self'; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob: http: https:; connect-src 'self' http: https:;" always;

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

  #############################################################################
  # Backup
  #############################################################################
  clan.core.state.pawtunes = {
    folders = [ appPath ];
    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }
      service_status=$(systemctl is-active pawtunes)
      if [ "$service_status" = "active" ]; then
        systemctl stop pawtunes
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/pawtunes/
        systemctl start pawtunes
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

      service_status="$(systemctl is-active pawtunes)"

      if [ "$service_status" = "active" ]; then
        systemctl stop pawtunes

        # Backup current pawtunes data locally
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/pawtunes/ "${appPath}/"

        # Fix permissions after restore
        chown -R ${appUser}:${appGroup} "${appPath}"

        systemctl start pawtunes
      fi
    '';
  };
}
