{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "radio.${domain}";
  appPath = "/data/docker/pawtunes";
  listenPort = 10008;

  version = "1.0.6";
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
  systemd.tmpfiles.rules = [
    "d ${appPath} 0750 root root -"
    "d ${appPath}/data 0750 33 33 -"
    "d ${appPath}/data/cache 0750 33 33 -"
    "d ${appPath}/inc 0750 33 33 -"
    "d ${appPath}/inc/config 0750 33 33 -"
    "d ${appPath}/inc/locale 0750 33 33 -"
    "d /var/backup/pawtunes 0750 root root -"
  ];

  virtualisation.oci-containers = {
    containers = {
      pawtunes = {
        image = "jackyprahec/pawtunes:${version}";
        autoStart = true;

        ports = [ "127.0.0.1:${toString listenPort}:80" ];

        volumes = [
          "${appPath}/inc/config:/var/www/html/inc/config"
          "${appPath}/inc/locale:/var/www/html/inc/locale"
          "${appPath}/data:/var/www/html/data"
        ];

        extraOptions = [
          "--cap-drop=ALL"
          # for nginx
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
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

      service_status=$(systemctl is-active docker-pawtunes)

      if [ "$service_status" = "active" ]; then
        systemctl stop docker-pawtunes
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/pawtunes/
        systemctl start docker-pawtunes
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

      service_status="$(systemctl is-active docker-pawtunes)"

      if [ "$service_status" = "active" ]; then
        systemctl stop docker-pawtunes

        # Backup localy current pawtunes data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/pawtunes/ "${appPath}/"

        systemctl start docker-pawtunes
      fi
    '';
  };
}
