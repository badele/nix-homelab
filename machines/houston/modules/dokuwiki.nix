{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  subDomain = "encyclopedie";
  authdomain = "douane.${domain}";
  appDomain = "${subDomain}.${domain}";

  version = "version-2025-05-14b";
  appPath = "/data/podman/dokuwiki";
  appId = 11;

  listenPort = 10000 + appId;
  subIdRangeStart = (100 + appId) * 100000;
  appUser = "dokuwiki";
  appGroup = "dokuwiki";

  containerUID = 1000;
  containerGID = 1000;
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
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.dokuwiki = {
    files.oauth2-client-secret = {
      owner = "dokuwiki";
      group = "dokuwiki";
      mode = "0400";
    };
    files.digest-client-secret = {
      owner = "dokuwiki";
      group = "dokuwiki";
      mode = "0400";
    };

    runtimeInputs = [
      pkgs.pwgen
      pkgs.authelia
      pkgs.gnugrep
      pkgs.gawk
    ];
    script = ''
      CLIENTSECRET="$(pwgen -s 48 1)"
      DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";

      echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
      echo "$DIGETSECRET" > "$out/digest-client-secret"
    '';
  };

  ############################################################################
  # Service configuration
  ############################################################################

  systemd.tmpfiles.rules = [
    # Enable linger for dokuwiki user
    "f /var/lib/systemd/linger/${appUser} 0644 root root - -"

    # Application data
    "d ${appPath} 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/config 0750 ${appUser} ${appGroup} -"

    # Backup directory
    "d /var/backup/dokuwiki 0750 ${appUser} ${appGroup} -"
  ];

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "dokuwiki";
      client_name = "dokuwiki bookmark manager";

      # clan vars get houston dokuwiki/digest-client-secret
      client_secret = "$argon2id$v=19$m=65536,t=3,p=4$S+NIPJHV+iAURvxfl4riLw$aQ4StjUv9CF2XOjSlr7VZtyGe9NoQSdMhuBeBfsi6OA";
      public = false;
      token_endpoint_auth_method = "client_secret_post";
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://${subDomain}.${config.networking.fqdn}/doku.php"
      ];
      response_types = [ "code" ];
      grant_types = [
        "authorization_code"
        "refresh_token"
      ];
      scopes = [
        "openid"
        "email"
        "profile"
        "groups"
        "offline_access"
      ];
    }
  ];

  systemd.services.dokuwiki = {
    description = "DokuWiki service (rootless podman)";
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
        "${pkgs.podman}/bin/podman pull linuxserver/dokuwiki:${version}"
        # Remove existing container if it exists
        "-${pkgs.podman}/bin/podman rm -f dokuwiki"
      ];

      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
          --rm \
          --name=dokuwiki \
          -p 127.0.0.1:${toString listenPort}:80 \
          -v ${appPath}/config:/config \
          # fix rootless => OAuth: An error occured during the request to the oauth provider: Could not connect to ssl://douane.ma-cabane.eu:443 (0) [HTTP -100]
          --add-host=${authdomain}:host-gateway \
          --env PUID=${toString containerUID} \
          --env PGID=${toString containerGID} \
          --cap-drop=ALL \
          --cap-add=CHOWN \
          --cap-add=SETUID \
          --cap-add=SETGID \
          --cap-add=DAC_OVERRIDE \
          --cap-add=NET_BIND_SERVICE \
          --cap-add=FOWNER \
          --cgroup-manager=cgroupfs \
          linuxserver/dokuwiki:${version}
      '';

      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 dokuwiki";
      ExecStopPost = "-${pkgs.podman}/bin/podman rm -f dokuwiki";
    };
  };

  services.nginx.virtualHosts."${appDomain}" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;

      extraConfig = ''
        access_log /var/log/nginx/public.log vcombined;

        # URL rewriting for DokuWiki
        # This allows clean URLs like /wiki/page instead of /doku.php?id=wiki:page
        rewrite ^/_media/(.*)              /lib/exe/fetch.php?media=$1  last;
        rewrite ^/_detail/(.*)             /lib/exe/detail.php?media=$1 last;
        rewrite ^/_export/([^/]+)/(.*)     /doku.php?do=export_$1&id=$2 last;
        rewrite ^/(?!lib/|_media|_detail|_export|doku\.php|feed\.php|install\.php)([^\?]*)(\?(.*))?$ /doku.php?id=$1&$3 last;

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
        # Note: DokuWiki needs 'unsafe-inline' for inline scripts/styles and CDN access
        # Relaxed CSP for DokuWiki compatibility with plugins and OAuth
        add_header Content-Security-Policy "default-src 'self'; font-src 'self' data: https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; img-src 'self' data: https: http:; media-src 'self' blob: https:; connect-src 'self' https: wss:; frame-ancestors 'self';" always;

        # Modern CORS headers (relaxed for OAuth flows)
        add_header Cross-Origin-Opener-Policy "same-origin-allow-popups" always;
        add_header Cross-Origin-Resource-Policy "cross-origin" always;

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
  clan.core.state.dokuwiki = {
    folders = [ appPath ];

    # Backup service data localy files, used by borgbackup
    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status=$(systemctl is-active dokuwiki)
      if [ "$service_status" = "active" ]; then
        systemctl stop dokuwiki
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/dokuwiki/
        systemctl start dokuwiki
      fi
    '';

    # Restore files to servei (files restored by borgbackup)
    postRestoreScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status="$(systemctl is-active dokuwiki)"

      if [ "$service_status" = "active" ]; then
        systemctl stop dokuwiki

        # Backup current dokuwiki data locally
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/dokuwiki/ "${appPath}/"

        # Fix permissions after restore
        chown -R ${appUser}:${appGroup} "${appPath}"

        systemctl start dokuwiki
      fi
    '';
  };
}
