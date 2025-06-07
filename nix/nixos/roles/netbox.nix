{ lib, config, pkgs, ... }:
let
  domain = config.homelab.domain;
  roleName = "netbox";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;

  borgbackup = config.homelab.borgBackup;
in
lib.mkIf (roleEnabled) {
  sops.secrets = {
    "services/netbox/secret" = {
      mode = "0400";
      owner = "netbox";
    };
  };

  services.netbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8001;
    secretKeyFile = config.sops.secrets."services/netbox/secret".path;
  };

  services.nginx = {
    enable = true;
    group = "netbox";
    virtualHosts."netbox-static" = {
      listen = [{
        addr = "127.0.0.1";
        port = 9001;
      }];
      locations."/" = { root = "${config.services.netbox.dataDir}"; };
    };
  };

  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        netbox = {
          rule =
            lib.mkDefault "Host(`netbox.${domain}`) && !PathPrefix(`/static`)";
          service = "netbox";
          entryPoints = [ "local" ];
        };
        "netbox-static" = {
          rule = "Host(`netbox.${domain}`) && PathPrefix(`/static`)";
          service = "netbox-static";
          entryPoints = [ "local" ];
        };
      };

      services = {
        netbox = {
          loadBalancer = { servers = [{ url = "http://localhost:8001"; }]; };
        };
        "netbox-static" = {
          loadBalancer.servers = [{ url = "http://127.0.0.1:9001"; }];
        };
      };
    };
  };

  services.borgbackup.jobs.netbox = {
    paths = [
      "/home"
      "/var/lib"
      "/tank/media/music"
      "/tank/scaningest"
      "/tank/softwarearchive"
      "/on-ssd"
    ];
    exclude = [
      "/tank/softwarearchive/MSDN"
      "/home/pmc/win-backup"
      "/var/lib/postgresql"
      "/var/lib/mysql"
    ];
    patterns = [ "- /**/*/.zfs/**/*" ];
    repo =
      "ssh://${borgbackup.users.netbox}@${borgbackup.address}:${borgbackup.port}/netbox";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /root/borgbackup/passphrase";
    };
    environment.BORG_RSH = "ssh -i /root/borgbackup/ssh_key";
    compression = "auto,lzma";
    startAt = "weekly";
    preHook = ''
      /run/wrappers/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dumpall -v -f /var/lib/postgres-backup/database.sql
      #/run/wrappers/bin/sudo -u mysql $ {pkgs.mysql80}/bin/mysqldump --all-databases --verbose --result-file=/var/lib/mysql-backup/database.sql
    '';
    readWritePaths = [ "/var/lib/postgres-backup" "/var/lib/mysql-backup" ];
  };

}
