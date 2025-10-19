{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "megaphone.${domain}";
  appPath = "/data/podman/shaarli";
  listenPort = 10005;

  rangeStart = listenPort * 10000;
  rangeCount = 9999;

  containerUID = 100; # nginx user (on container)
  containerGID = 101; # nginx group (on container)

  hostUID = rangeStart + containerUID;
  hostGID = rangeStart + containerGID;

  # Image
  version = "v0.12.2";

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
  users.users.shaarli = {
    isSystemUser = true;
    group = "shaarli";
    uid = hostUID;
  };
  users.groups.shaarli.gid = hostGID;

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

  systemd.tmpfiles.rules = [
    "d ${appPath}/data 0750 shaarli shaarli -"
    "d ${appPath}/cache 0750 shaarli shaarli -"
    "d /var/backup/shaarli 0750 shaarli shaarli -"
  ];

  virtualisation.oci-containers = {
    containers = {
      shaarli = {
        image = "shaarli/shaarli:${version}";
        autoStart = true;
        ports = [ "${toString listenPort}:80" ];

        volumes = [
          "${appPath}/data:/var/www/shaarli/data"
          "${appPath}/cache:/var/www/shaarli/cache"
        ];

        extraOptions = [
          "--uidmap=0:${toString rangeStart}:${toString rangeCount}"
          "--gidmap=0:${toString rangeStart}:${toString rangeCount}"
        ];
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
  clan.core.state.shaarli = {
    folders = [ appPath ];

    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status=$(systemctl is-active podman-shaarli)

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-shaarli
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/shaarli/
        systemctl start podman-shaarli
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

      service_status="$(systemctl is-active podman-shaarli)"

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-shaarli

        # Backup localy current shaarli data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/shaarli/ "${appPath}/"

        systemctl start podman-shaarli
      fi
    '';
  };
}
