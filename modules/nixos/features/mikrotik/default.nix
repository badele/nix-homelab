{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  ...
}:
with lib;
with types;

let
  appName = "mikrotik";
  serviceName = "mikrotik-backup";
  cfg = config.homelab.features.${appName};

  routerOptions = {
    options = {
      name = mkOption {
        type = str;
        description = "Router name used for local backup directory names.";
      };

      host = mkOption {
        type = str;
        description = "Router SSH hostname or IP address.";
      };

      port = mkOption {
        type = port;
        default = 22;
        description = "Router SSH port.";
      };

      user = mkOption {
        type = str;
        default = "backup";
        description = "RouterOS user used to create and fetch backups.";
      };
    };
  };

  routersFile = pkgs.writeText "mikrotik-routers.json" (builtins.toJSON cfg.routers);
  backupRoot = cfg.backupRoot;
  sshKeyFile = config.clan.core.vars.generators.${appName}.files."ssh.id_ed25519".path;
  ageKeyFile = config.clan.core.vars.generators.${appName}.files."age.key".path;
  generatedAgeRecipientFile = config.clan.core.vars.generators.${appName}.files."age.pub".path;
  configuredAgeRecipient = if cfg.ageRecipient == null then "" else cfg.ageRecipient;
  retention = cfg.retention;
  sshKeyComment = "${serviceName}@${config.networking.hostName}";

  backupScript = import ./backup-script.nix {
    inherit
      pkgs
      serviceName
      routersFile
      backupRoot
      sshKeyFile
      generatedAgeRecipientFile
      configuredAgeRecipient
      retention
      ;
  };

  listBackupScript = import ./list-backup-script.nix {
    inherit
      pkgs
      backupRoot
      ;
  };

  restoreBackupScript = import ./restore-backup-script.nix {
    inherit
      pkgs
      ageKeyFile
      sshKeyFile
      ;
  };
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      backup = mkEnableOption "MikroTik configuration backups";

      prometheus = mkEnableOption "MikroTik Prometheus integration";

      routers = mkOption {
        type = listOf (submodule routerOptions);
        default = [ ];
        description = "MikroTik routers backed up by this feature.";
      };

      backupRoot = mkOption {
        type = str;
        default = "/data/backup/mikrotik";
        description = "Root directory used to store encrypted MikroTik backups.";
      };

      retention = mkOption {
        type = ints.positive;
        default = 30;
        description = "Number of encrypted backup/export files to retain per router.";
      };

      calendar = mkOption {
        type = str;
        default = "03:30";
        description = "Systemd OnCalendar expression for MikroTik backups.";
      };

      ageRecipient = mkOption {
        type = nullOr str;
        default = null;
        description = "Optional age recipient. If unset, the generated MikroTik age key is used.";
      };

      sshKnownHosts = mkOption {
        type = attrsOf str;
        default = { };
        description = "Known host public keys indexed by router host.";
      };
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
    {
      homelab.features.${appName}.appInfos = {
        category = "Core Services";
        displayName = "MikroTik";
        icon = "mikrotik";
        platform = "nixos";
        description = "MikroTik RouterOS management helpers";
        url = "https://mikrotik.com/";
        pinnedVersion = "";
        serviceURL = "";
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.backup || cfg.routers != [ ];
          message = "homelab.features.mikrotik.backup requires at least one router in homelab.features.mikrotik.routers.";
        }
        {
          assertion = !cfg.prometheus;
          message = "homelab.features.mikrotik.prometheus is declared but not implemented yet.";
        }
      ];

      users.groups.${appName} = { };

      users.users.${appName} = {
        isSystemUser = true;
        group = appName;
        home = "/var/lib/${appName}";
        createHome = true;
      };

      clan.core.vars.generators.${appName} = {
        files = {
          "ssh.id_ed25519" = {
            owner = appName;
            group = appName;
          };
          "ssh.id_ed25519.pub" = {
            secret = false;
          };
          "age.key" = {
            owner = appName;
            group = appName;
          };
          "age.pub" = {
            secret = false;
          };
        };

        runtimeInputs = [
          pkgs.age
          pkgs.openssh
        ];

        script = ''
          ssh-keygen -q -N "" -t ed25519 -C "${sshKeyComment}" -f "$out/ssh.id_ed25519"
          cp "$out/ssh.id_ed25519.pub" "$out/ssh.id_ed25519.pub.tmp"
          mv "$out/ssh.id_ed25519.pub.tmp" "$out/ssh.id_ed25519.pub"

          age-keygen -o "$out/age.key"
          age-keygen -y "$out/age.key" > "$out/age.pub"
        '';
      };

      programs.ssh.knownHosts = mapAttrs (_: publicKey: { inherit publicKey; }) cfg.sshKnownHosts;
    })

    (mkIf (cfg.enable && cfg.backup) {
      environment.systemPackages = [
        listBackupScript
        restoreBackupScript
      ];

      programs.bash.shellAliases = (mkServiceAliases serviceName) // {
        "@mikrotik-list-backup-for-router" = "mikrotik-list-backup-for-router";
        "@mikrotik-restore-backup-file-for-router" = "mikrotik-restore-backup-file-for-router";
        "@service-${serviceName}-config" = "systemctl cat ${serviceName}";
      };

      systemd.tmpfiles.rules = [
        "d ${backupRoot} 0750 ${appName} ${appName} -"
        "d /var/lib/${appName}/.ssh 0700 ${appName} ${appName} -"
      ];

      systemd.services.${serviceName} = {
        description = "Backup MikroTik RouterOS configurations";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = appName;
          Group = appName;
          ExecStart = "${backupScript}/bin/${serviceName}";
          StateDirectory = appName;
          UMask = "0077";
        };
      };

      systemd.timers.${serviceName} = {
        description = "Run MikroTik RouterOS configuration backups";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.calendar;
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
    })
  ];
}
