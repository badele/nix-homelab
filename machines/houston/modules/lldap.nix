{
  config,
  lib,
  pkgs,
  ...
}:
let

  image = "lldap/lldap";
  version = "2025-09-28-alpine";
  appPath = "/data/podman/lldap";
  appId = 10;

  subIdRangeStart = (100 + appId) * 100000;
  appUser = "lldap";
  appGroup = "lldap";

  containerUID = 1000; # app user (on container)
  containerGID = 1000; # app group (on container)
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  ############################################################################
  # Rootless podman user
  ############################################################################
  users = {
    users.${appUser} = {
      isSystemUser = true;
      group = appGroup;
      home = "/var/lib/podman/users/${appUser}";
      createHome = true;
      subUidRanges = [
        {
          startUid = subIdRangeStart;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = subIdRangeStart;
          count = 65536;
        }
      ];
    };
    groups.${appGroup} = { };
  };

  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.lldap = {
    files.jwt-secret = {
      owner = "lldap";
      group = "lldap";
      mode = "0400";
    };
    files.password = {
      owner = "lldap";
      group = "lldap";
      mode = "0400";
    };
    files.envfile = {
      owner = "lldap";
      group = "lldap";
      mode = "0400";
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

  ############################################################################
  # Service configuration
  ############################################################################

  systemd.tmpfiles.rules = [
    # Enable linger for lldap user
    "f /var/lib/systemd/linger/${appUser} 0644 root root - -"

    # Application data
    "d ${appPath} 0750 ${appUser} ${appGroup} -"
    "d ${appPath}/data 0750 ${appUser} ${appGroup} -"

    # Backup directory
    "d /var/backup/lldap 0750 ${appUser} ${appGroup} -"
  ];

  systemd.services.lldap = {
    description = "LLDAP authentication service (rootless podman)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    # Required to make `newuidmap` available to the systemd service
    path = [
      "/run/wrappers"
      pkgs.podman
    ];

    serviceConfig = {
      Type = "simple";
      User = appUser;
      Group = appGroup;

      # Load credentials
      LoadCredential = [
        "jwt-secret:${config.clan.core.vars.generators."lldap".files."jwt-secret".path}"
        "password:${config.clan.core.vars.generators."lldap".files."password".path}"
        "envfile:${config.clan.core.vars.generators."lldap".files."envfile".path}"
      ];

      # Restart policy
      Restart = "on-failure";
      RestartSec = "30s";
      TimeoutStartSec = 120;
      TimeoutStopSec = 120;

      ExecStartPre = [
        # Pull the image if needed
        "${pkgs.podman}/bin/podman pull ${image}:${version}"
        # Remove existing container if it exists
        "-${pkgs.podman}/bin/podman rm -f lldap"
      ];

      ExecStart = ''
        ${pkgs.podman}/bin/podman run \
          --rm \
          --name=lldap \
          -p 3890:3890 \
          -p 17170:17170 \
          -v ${appPath}/data:/data \
          -v ''${CREDENTIALS_DIRECTORY}/jwt-secret:/run/secrets/jwt-secret:ro \
          -v ''${CREDENTIALS_DIRECTORY}/password:/run/secrets/password:ro \
          --env-file=''${CREDENTIALS_DIRECTORY}/envfile \
          --env LLDAP_LDAP_BASE_DN=dc=homelab,dc=lan \
          --env LLDAP_JWT_SECRET_FILE=/run/secrets/jwt-secret \
          --env LLDAP_LDAP_USER_PASS_FILE=/run/secrets/password \
          --cap-drop=ALL \
          --cap-add=CHOWN \
          --cap-add=SETUID \
          --cap-add=SETGID \
          --cap-add=DAC_OVERRIDE \
          --userns=keep-id:uid=${toString containerUID},gid=${toString containerGID} \
          --cgroup-manager=cgroupfs \
          ${image}:${version}
      '';

      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 lldap";
      ExecStopPost = "-${pkgs.podman}/bin/podman rm -f lldap";
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

      service_status=$(systemctl is-active lldap)
      if [ "$service_status" = "active" ]; then
        systemctl stop lldap
        rsync -avH --delete --numeric-ids "${appPath}/" /var/backup/lldap/
        systemctl start lldap
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

      service_status="$(systemctl is-active lldap)"

      if [ "$service_status" = "active" ]; then
        systemctl stop lldap

        # Backup current lldap data locally
        DATE=$(date +%Y%m%d-%H%M%S)
        cp -rp "${appPath}" "${appPath}.$DATE.bak"

        # Restore from borgbackup
        rsync -avH --delete --numeric-ids /var/backup/lldap/ "${appPath}/"

        # Fix permissions after restore
        chown -R ${appUser}:${appGroup} "${appPath}"

        systemctl start lldap
      fi
    '';
  };
}
