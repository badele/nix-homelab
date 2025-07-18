{ lib, config, pkgs, ... }:
let
  domain = config.homelab.domain;
  roleName = "netbox";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;

  borgbackup = config.homelab.borgBackup;
in lib.mkIf (roleEnabled) {
  sops.secrets = {
    "services/netbox/secret" = {
      mode = "0400";
      owner = "netbox";
    };

    "borgbackup/passphrase/netbox" = {
      sopsFile = ./../../../configuration/hosts/secrets.yml;
    };
  };

  ############################################################################
  # netbox service
  ############################################################################
  services.netbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8001;
    secretKeyFile = config.sops.secrets."services/netbox/secret".path;

    plugins = python313Packages:
      with python313Packages;
      [ netbox-topology-views ];
    settings = { PLUGINS = [ "netbox_topology_views" ]; };

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

  ############################################################################
  # backup
  ############################################################################
  services.borgbackup.jobs.netbox = {
    paths = [ "/data/borgbackup/postgresql/netbox" ];
    repo = "${borgbackup.remote}/./netbox";
    doInit = true;

    encryption = {
      mode = "repokey-blake2";
      passCommand =
        "cat ${config.sops.secrets."borgbackup/passphrase/netbox".path}";
    };
    environment = {
      BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
      # BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
    };
    preHook = ''
      rm -rf /data/borgbackup/postgresql/netbox
      ${
        lib.getExe pkgs.sudo
      } -u postgres ${pkgs.postgresql}/bin/pg_dump -F directory -f /data/borgbackup/postgresql/netbox netbox
    '';
    postCreate = ''
      rm -rf /data/borgbackup/postgresql/netbox
    '';
    readWritePaths = [ "/data/borgbackup/postgresql" ];
    compression = "auto,zlib";
    startAt = "daily";
  };
}
