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
  appPath = "/data/podman/dokuwiki";
  listenPort = 10011; # reserver pod (not used)

  rangeStart = listenPort * 10000;
  rangeCount = 9999;

  containerUID = 1000;
  containerGID = 1000;

  hostUID = rangeStart + containerUID;
  hostGID = rangeStart + containerGID;

  # Image
  version = "version-2025-05-14b";
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
  users.users.dokuwiki = {
    isSystemUser = true;
    group = "dokuwiki";
    uid = hostUID;
  };
  users.groups.dokuwiki.gid = hostGID;

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
  clan.core.vars.generators.dokuwiki = {
    files.oauth2-client-secret = { };
    files.digest-client-secret = { };

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

  systemd.tmpfiles.rules = [
    "d ${appPath} 0750 dokuwiki dokuwiki  -"
    "d ${appPath}/config 0750 dokuwiki dokuwiki  -"
    "d /var/backup/dokuwiki 0750 dokuwiki dokuwiki -"
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

  virtualisation.oci-containers = {
    containers = {
      dokuwiki = {
        image = "linuxserver/dokuwiki:${version}";
        autoStart = true;
        ports = [ "127.0.0.1:${toString listenPort}:80" ];

        volumes = [ "${appPath}/config:/config" ];

        extraOptions = [
          "--uidmap=0:${toString rangeStart}:${toString rangeCount}"
          "--gidmap=0:${toString rangeStart}:${toString rangeCount}"
        ];

        environment = {
          PUID = "${toString containerUID}";
          PGID = "${toString containerGID}";
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
        access_log /var/log/nginx/public.log vcombined;

        # URL rewriting for DokuWiki
        # This allows clean URLs like /wiki/page instead of /doku.php?id=wiki:page
        rewrite ^/_media/(.*)              /lib/exe/fetch.php?media=$1  last;
        rewrite ^/_detail/(.*)             /lib/exe/detail.php?media=$1 last;
        rewrite ^/_export/([^/]+)/(.*)     /doku.php?do=export_$1&id=$2 last;
        rewrite ^/(?!lib/|_media|_detail|_export|doku\.php|feed\.php|install\.php)([^\?]*)(\?(.*))?$ /doku.php?id=$1&$3 last;
      '';
    };
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

      service_status=$(systemctl is-active podman-dokuwiki)
      if [ "$service_status" = "active" ]; then
        systemctl stop podman-dokuwiki
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/dokuwiki/
        systemctl start podman-dokuwiki
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

      service_status="$(systemctl is-active podman-dokuwiki)"
      if [ "$service_status" = "active" ]; then
        systemctl stop podman-dokuwiki

        # Backup localy current dokuwiki data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/dokuwiki/ "${appPath}/"

        systemctl start podman-dokuwiki
      fi
    '';
  };
}
