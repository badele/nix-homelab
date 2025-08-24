{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  authdomain = "auth.${domain}";
  appDomain = "links.${domain}";
  appPath = "/data/podman/linkding";
  listenPort = 10004;

  version = "1.41.0-plus";
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
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.linkding = {
    files.oauth2-client-secret = {
      owner = "linkding";
      group = "authelia-main";
      mode = "0440";
    };
    files.digest-client-secret = {
      owner = "linkding";
      group = "authelia-main";
      mode = "0440";
    };
    files.linkding-env = {
      owner = "linkding";
      group = "authelia-main";
      mode = "0440";
    };

    runtimeInputs = [
      pkgs.pwgen
      pkgs.authelia
      pkgs.gnugrep
      pkgs.gawk
    ];
    script = ''
      CLIENTSECRET="$(pwgen -s 48 1)"
      BOOKADMIN="$(pwgen -s 16 1)"
      DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";

      echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
      echo "$DIGETSECRET" > "$out/digest-client-secret"

      printf "OIDC_RP_CLIENT_SECRET=$CLIENTSECRET\nLD_SUPERUSER_NAME=bookadmin\nLD_SUPERUSER_PASSWORD=$BOOKADMIN"  > "$out/linkding-env"
    '';
  };

  ############################################################################
  # Service configuration
  ############################################################################
  users.users.linkding = {
    isSystemUser = true;
    group = "linkding";
    createHome = true;
    home = appPath;
    homeMode = "0774";
  };

  users.groups.linkding = { };

  systemd.tmpfiles.rules = [
    "d ${appPath} 0750 linkding linkding -"
    "d /var/backup/linkding 0750 linkding linkding -"
  ];

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
        "https://links.${config.networking.fqdn}/oidc/callback/"
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
      linkding = {
        image = "ghcr.io/sissbruecker/linkding:${version}";
        autoStart = true;
        user = "${toString config.users.users.linkding.uid}:${toString config.users.groups.linkding.gid}";
        ports = [ "127.0.0.1:${toString listenPort}:9090" ];

        volumes = [ "${appPath}:/etc/linkding/data" ];

        # extraOptions = [
        #   "--security-opt=no-new-privileges:true"
        #   "--cap-drop=ALL"
        #   "--cap-add=CHOWN"
        #   "--cap-add=SETGID"
        #   "--cap-add=SETUID"
        #   "--read-only"
        #   "--tmpfs=/tmp:rw,noexec,nosuid,size=100m"
        #   "--tmpfs=/var/tmp:rw,noexec,nosuid,size=50m"
        #   "--pids-limit=100"
        #   "--memory=512m"
        #   "--cpus=1.0"
        #   "--restart=unless-stopped"
        # ];
        #
        environmentFiles = [
          config.clan.core.vars.generators."linkding".files."linkding-env".path
        ];
        environment = {
          # https://github.com/sissbruecker/linkding/blob/4e8318d0ae5859f61fbc05ec0cc007cd00247eb2/docs/src/content/docs/options.md#oidc-and-ld_superuser_name
          LD_ENABLE_OIDC = "true";

          OIDC_OP_AUTHORIZATION_ENDPOINT = "https://${authdomain}/api/oidc/authorization";
          OIDC_OP_TOKEN_ENDPOINT = "https://${authdomain}/api/oidc/token";
          OIDC_OP_USER_ENDPOINT = "https://${authdomain}/api/oidc/userinfo";
          OIDC_OP_JWKS_ENDPOINT = "https://${authdomain}/jwks.json";
          OIDC_RP_CLIENT_ID = "linkding";
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
    };
    extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
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

      service_status=$(systemctl is-active podman-linkding)

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-linkding
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/linkding/
        systemctl start podman-linkding
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

      service_status="$(systemctl is-active podman-linkding)"

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-linkding

        # Backup localy current linkding data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/linkding/ "${appPath}/"

        systemctl start podman-linkding
      fi
    '';
  };
}
