{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "veille.${domain}";
  appPath = "/data/podman/shaarli";
  listenPort = 10005;

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
  # Service configuration
  ############################################################################
  users.users.shaarli = {
    isSystemUser = true;
    group = "shaarli";
    createHome = true;
    home = appPath;
    homeMode = "0774";
  };

  users.groups.shaarli = { };

  systemd.tmpfiles.rules = [
    "d ${appPath}/data 0750 100 101 -"
    "d ${appPath}/cache 0750 100 101 -"
    "d /var/backup/shaarli 0750 shaarli shaarli -"
  ];

  virtualisation.oci-containers = {
    containers = {
      shaarli = {
        image = "shaarli/shaarli:${version}";
        autoStart = true;
        user = "${toString config.users.users.shaarli.uid}:${toString config.users.groups.shaarli.gid}";
        ports = [ "127.0.0.1:${toString listenPort}:80" ];

        volumes = [
          "${appPath}/data:/var/www/shaarli/data"
          "${appPath}/cache:/var/www/shaarli/cache"
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
