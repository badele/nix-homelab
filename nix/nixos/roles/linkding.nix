{ lib, config, pkgs, ... }:
let
  host = "links";
  domain = config.homelab.domain;
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
  roleName = "linkding";
  version = "1.41.0-plus";

  borgbackup = config.homelab.borgBackup;
in lib.mkIf (roleEnabled) {
  sops.secrets = {
    "services/linkding/superuser-password" = { };
    "borgbackup/passphrase/linkding" = {
      sopsFile = ./../../../configuration/hosts/secrets.yml;
    };
  };

  sops.templates."linkding-env".content = ''
    LD_SUPERUSER_PASSWORD=${
      config.sops.placeholder."services/linkding/superuser-password"
    }
  '';

  ############################################################################
  # linkding service
  ############################################################################
  systemd.tmpfiles.rules = [ "d /data/docker/${roleName} 0750 33 33 -" ];

  virtualisation.oci-containers.containers = {
    linkding = {
      image = "ghcr.io/sissbruecker/linkding:${version}";
      autoStart = true;
      # user = "1000:100";
      ports = [ "9090:9090" ];

      volumes = [ "/data/docker/${roleName}:/etc/linkding/data" ];
      environmentFiles = [ config.sops.templates."linkding-env".path ];
      environment = {
        LD_SUPERUSER_NAME = "badele";
        LD_CSRF_TRUSTED_ORIGINS = "http://${host}.${domain}";
      };
    };
  };

  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        linkding = {
          rule = lib.mkDefault "Host(`${host}.${domain}`)";
          service = "linkding";
          entryPoints = [ "local" ];
        };
      };

      services = {
        linkding = {
          loadBalancer = { servers = [{ url = "http://localhost:9090"; }]; };
        };
      };
    };
  };

  ############################################################################
  # backup
  ############################################################################
  services.borgbackup.jobs.linkding = {
    paths = [ "/data/docker/linkding" ];
    repo = "${borgbackup.remote}/./linkding";
    doInit = true;

    encryption = {
      mode = "repokey-blake2";
      passCommand =
        "cat ${config.sops.secrets."borgbackup/passphrase/linkding".path}";
    };
    environment = {
      BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
      # BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
    };
    preHook = ''
      ${lib.getExe pkgs.sudo} systemctl stop docker-linkding
    '';
    postCreate = ''
      ${lib.getExe pkgs.sudo} systemctl start docker-linkding
    '';
    readWritePaths = [ "/data/docker/linkding" ];
    compression = "auto,zlib";
    startAt = "daily";
  };

}
