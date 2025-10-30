{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  subDomain = "bonnes-adresses";
  authdomain = "douane.${domain}";
  appDomain = "${subDomain}.${domain}";

  version = "1.41.0-plus";
  appPath = "/data/podman/linkding";
  appId = 4;

  listenPort = 10000 + appId;
  subIdRangeStart = (100 + appId) * 100000;
  appUser = "linkding";
  appGroup = "linkding";
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
  clan.core.vars.generators.linkding = {
    files.oauth2-client-secret = {
      owner = "linkding";
      group = "linkding";
      mode = "0400";
    };
    files.digest-client-secret = {
      owner = "linkding";
      group = "linkding";
      mode = "0400";
    };
    files.envfile = {
      owner = "linkding";
      group = "linkding";
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
      ADMINPASSWORD="$(pwgen -s 16 1)"
      DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";

      echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
      echo "$DIGETSECRET" > "$out/digest-client-secret"

      cat > "$out/envfile" << EOF
      OIDC_RP_CLIENT_SECRET=$CLIENTSECRET
      LD_SUPERUSER_NAME=bookadmin
      LD_SUPERUSER_PASSWORD=$ADMINPASSWORD
      EOF
    '';
  };

  ############################################################################
  # Service configuration
  ############################################################################

  systemd.tmpfiles.rules = [
    # Enable linger for linkding user
    "f /var/lib/systemd/linger/${appUser} 0644 root root - -"

    # Application data
    "d ${appPath} 0750 ${appUser} ${appGroup} -"

    # Backup directory
    "d /var/backup/linkding 0750 ${appUser} ${appGroup} -"
  ];

  systemd.services.linkding = {
    description = "Linkding bookmark manager service (rootless podman)";
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
        "${pkgs.podman}/bin/podman pull ghcr.io/sissbruecker/linkding:${version}"
        # Remove existing container if it exists
        "-${pkgs.podman}/bin/podman rm -f linkding"
      ];

      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
          --rm \
          --name=linkding \
          -p 127.0.0.1:${toString listenPort}:9090 \
          -v ${appPath}:/etc/linkding/data \
          --env-file=${config.clan.core.vars.generators."linkding".files."envfile".path} \
          --env LD_ENABLE_OIDC=true \
          --env OIDC_OP_AUTHORIZATION_ENDPOINT=https://${authdomain}/api/oidc/authorization \
          --env OIDC_OP_TOKEN_ENDPOINT=https://${authdomain}/api/oidc/token \
          --env OIDC_OP_USER_ENDPOINT=https://${authdomain}/api/oidc/userinfo \
          --env OIDC_OP_JWKS_ENDPOINT=https://${authdomain}/jwks.json \
          --env OIDC_RP_CLIENT_ID=linkding \
          --cap-drop=ALL \
          --cap-add=CHOWN \
          --cap-add=SETUID \
          --cap-add=SETGID \
          --cap-add=DAC_OVERRIDE \
          --cap-add=NET_BIND_SERVICE \
          --userns=keep-id:uid=33,gid=33 \
          --cgroup-manager=cgroupfs \
          ghcr.io/sissbruecker/linkding:${version}
      '';

      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 linkding";
      ExecStopPost = "-${pkgs.podman}/bin/podman rm -f linkding";
    };
  };

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "linkding";
      client_name = "Linkding bookmark manager";

      # clan vars get houston linkding/digest-client-secret
      client_secret = "$argon2id$v=19$m=65536,t=3,p=4$9+1pxmhPJ+HEx2PgIZ7L5g$9r7vpIpy/oCk/136W7AohILJhWY0fhy9Z6CwiviDoO0";
      public = false;
      token_endpoint_auth_method = "client_secret_post";
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://${subDomain}.${config.networking.fqdn}/oidc/callback/"
      ];
      scopes = [
        "openid"
        "email"
        "profile"
      ];
    }
  ];

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
        add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; media-src 'self' blob: https:; connect-src 'self' https:;" always;

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
  clan.core.state.linkding = {
    folders = [ appPath ];
    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status=$(systemctl is-active linkding)
      if [ "$service_status" = "active" ]; then
        systemctl stop linkding
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/linkding/
        systemctl start linkding
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

      service_status="$(systemctl is-active linkding)"

      if [ "$service_status" = "active" ]; then
        systemctl stop linkding

        # Backup current linkding data locally
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/linkding/ "${appPath}/"

        # Fix permissions after restore
        chown -R ${appUser}:${appGroup} "${appPath}"

        systemctl start linkding
      fi
    '';
  };
}
