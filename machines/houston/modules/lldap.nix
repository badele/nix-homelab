{
  config,
  lib,
  pkgs,
  ...
}:
let
  appPath = "/data/podman/lldap";
  listenPort = 10010; # Private hosting, unused port (but reserved)

  rangeStart = listenPort * 10000;
  rangeCount = 9999;

  containerUID = 1000; # app user (on container)
  containerGID = 1000; # app group (on container)

  hostUID = rangeStart + containerUID;
  hostGID = rangeStart + containerGID;

  image = "lldap/lldap";
  version = "2025-09-28-alpine";
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  ############################################################################
  # Container user mapping
  ############################################################################
  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
    uid = hostUID;
  };
  users.groups.lldap.gid = hostGID;

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
  clan.core.vars.generators.lldap = {
    files.jwt-secret = {
      owner = "lldap";
      group = "lldap";
      mode = "0444";
    };
    files.password = {
      owner = "lldap";
      group = "lldap";
      mode = "0444";
    };
    files.envfile = {
      owner = "lldap";
      group = "lldap";
      mode = "0444";
    };

    runtimeInputs = [
      pkgs.pwgen
    ];

    script = ''
      pwgen -s 32 1 > "$out/jwt-secret"
      pwgen -s 16 1 > "$out/password"

      KEYSEED="$(pwgen -s 32 1)"
      cat > "$out/envfile" << EOF
      LLDAP_KEY_SEED=$KEYSEED
      EOF

    '';
  };

  systemd.tmpfiles.rules = [
    "d ${appPath} 0750 lldap lldap -"
    "d ${appPath}/data 0750 lldap lldap -"
    "d /var/backup/lldap 0750 lldap lldap -"
  ];

  virtualisation.oci-containers = {
    containers = {
      lldap = {
        image = "${image}:${version}";
        autoStart = true;
        ports = [
          "3890:3890"
          "17170:17170"
        ];

        volumes = [
          "${appPath}/data:/data"
          "/run/secrets/vars/lldap/jwt-secret:/run/secrets/jwt-secret:ro"
          "/run/secrets/vars/lldap/password:/run/secrets/password:ro"
        ];

        extraOptions = [
          "--uidmap=0:${toString rangeStart}:${toString rangeCount}"
          "--gidmap=0:${toString rangeStart}:${toString rangeCount}"
        ];

        environmentFiles = [
          config.clan.core.vars.generators."lldap".files."envfile".path
        ];

        environment = {
          LLDAP_LDAP_BASE_DN = "dc=homelab,dc=lan";

          LLDAP_JWT_SECRET_FILE = "/run/secrets/jwt-secret";
          LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/password";

        };
      };
    };
  };

  #############################################################################
  # Backup
  #############################################################################
  clan.core.state.lldap = {
    folders = [ appPath ];

    preBackupScript = ''
      export PATH=${
        lib.makeBinPath [
          config.systemd.package
          pkgs.coreutils
          pkgs.rsync
        ]
      }

      service_status=$(systemctl is-active podman-lldap)

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-lldap
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/lldap/
        systemctl start podman-lldap
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

      service_status="$(systemctl is-active podman-lldap)"

      if [ "$service_status" = "active" ]; then
        systemctl stop podman-lldap

        # Backup localy current lldap data
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/lldap/ "${appPath}/"

        systemctl start podman-lldap
      fi
    '';
  };
}
