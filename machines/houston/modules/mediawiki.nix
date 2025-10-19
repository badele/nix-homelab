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
  appPath = "/data/podman/mediawiki";
  listenPort = 10011;

  rangeStart = listenPort * 10000;
  rangeCount = 9999;

  containerUID = 33; # root user (on container)
  containerGID = 33; # root group (on container)

  hostUID = rangeStart + containerUID;
  hostGID = rangeStart + containerGID;

  # Image
  version = "1.44.2";
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];

  ############################################################################
  # Container user mapping
  ############################################################################
  users.users.mediawiki = {
    isSystemUser = true;
    group = "mediawiki";
    uid = hostUID;
  };
  users.groups.mediawiki.gid = hostGID;

  # Podman rootless configuration
  # podman run with root account
  users.users.root.subUidRanges = [
    {
      startUid = rangeStart;
      count = rangeCount;
    }
  ];
  users.users.root.subGidRanges = [
    {
      startGid = rangeStart;
      count = rangeCount;
    }
  ];

  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.mediawiki = {
    files.oauth2-client-secret = { };
    files.digest-client-secret = { };
    files.envfile = { };

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

  systemd.tmpfiles.rules = [
    "d ${appPath} 0750 mediawiki mediawiki  -"
    "d /var/backup/mediawiki 0750 mediawiki mediawiki -"
  ];

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "mediawiki";
      client_name = "mediawiki bookmark manager";

      # clan vars get houston mediawiki/digest-client-secret
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

  virtualisation.oci-containers = {
    containers = {
      mediawiki = {
        image = "mediawiki:${version}";
        autoStart = true;
        ports = [ "127.0.0.1:${toString listenPort}:80" ];

        volumes = [ "${appPath}:/etc/mediawiki/data" ];

        extraOptions = [
          "--uidmap=0:${toString rangeStart}:${toString rangeCount}"
          "--gidmap=0:${toString rangeStart}:${toString rangeCount}"
        ];
        # extraOptions = [
        #   "--cap-drop=ALL"
        #   # for nginx
        #   "--cap-add=CHOWN"
        #   "--cap-add=SETUID"
        #   "--cap-add=SETGID"
        #   "--cap-add=DAC_OVERRIDE"
        # ];

        environmentFiles = [
          config.clan.core.vars.generators."mediawiki".files."envfile".path
        ];
        environment = {
          # https://github.com/sissbruecker/mediawiki/blob/4e8318d0ae5859f61fbc05ec0cc007cd00247eb2/docs/src/content/docs/options.md#oidc-and-ld_superuser_name
          LD_ENABLE_OIDC = "true";

          OIDC_OP_AUTHORIZATION_ENDPOINT = "https://${authdomain}/api/oidc/authorization";
          OIDC_OP_TOKEN_ENDPOINT = "https://${authdomain}/api/oidc/token";
          OIDC_OP_USER_ENDPOINT = "https://${authdomain}/api/oidc/userinfo";
          OIDC_OP_JWKS_ENDPOINT = "https://${authdomain}/jwks.json";
          OIDC_RP_CLIENT_ID = "mediawiki";
        };
      };
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
        # Forward auth to Authelia
        auth_request /authelia;

        # Transmit headers for authentification
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $email $upstream_http_remote_email;

        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Email $email;

        # Error redirection
        error_page 401 =302 https://douane.${config.networking.fqdn}/?rd=$scheme://$http_host$request_uri;
      '';
    };

    locations."/authelia" = {
      proxyPass = "http://127.0.0.1:9091/api/verify";
      extraConfig = ''
        internal;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-Method $request_method;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Content-Length "";
        proxy_pass_request_body off;
      '';
    };

    extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
  };

  #############################################################################
  # Backup
  #############################################################################
  clan.core.state.mediawiki = {
    folders = [ appPath ];

    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status=$(systemctl is-active podman-mediawiki)

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-mediawiki
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/mediawiki/
        systemctl start podman-mediawiki
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

      service_status="$(systemctl is-active podman-mediawiki)"

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-mediawiki

        # Backup localy current mediawiki data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/mediawiki/ "${appPath}/"

        systemctl start podman-mediawiki
      fi
    '';
  };
}
