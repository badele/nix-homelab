{
  lib,
  pkgs,
  config,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };
in
{
  # Source: https://framagit.org/ppom/nixos/-/blob/main/modules/common/reaction-custom.nix
  options.services.reaction =
    with lib;
    with types;
    {
      enable = mkEnableOption "enable reaction";

      package = mkOption {
        type = package;
        description = "The reaction package to use";
        default = pkgs.reaction;
      };

      settings = mkOption {
        description = ''
          Configuration for reaction. See the [wiki](https://framagit.org/ppom/reaction-wiki)

          The settings are compiled into a YAML file.

          Mutually exclusive option `settingsFile`.
        '';
        default = { };
        type = submodule {
          freeformType = settingsFormat.type;
          options = { };
        };
      };

      settingsFile = mkOption {
        description = ''
          Configuration for reaction, see the [wiki](https://framagit.org/ppom/reaction-wiki)

          reaction supports JSON, YAML and JSONnet. For those who prefer to take advantage of JSONnet rather than Nix.

          Mutually exclusive with `settings`
        '';
        default = null;
        type = nullOr path;
      };

      loglevel = mkOption {
        description = ''
          Daemon's loglevel, one of DEBUG, INFO, WARN, ERROR
        '';
        default = null;
        type = nullOr (enum [
          "DEBUG"
          "INFO"
          "WARN"
          "ERROR"
        ]);
      };

      runAsRoot = mkOption {
        type = bool;
        default = false;
        description = lib.mdDoc ''
          Whether to run reaction as root.
          Defaults to false, where an unprivileged reaction user is created.
          Be sure to give it sufficient permissions.
          Example config permitting `iptables` and `journalctl` use
          ```nix
          {
            users.users.reaction.extraGroups = [ "systemd-journal" ];

            security.sudo.extraRules = [{
              users = [ "reaction" ];
              cmd = "$${pkgs.iptables}/bin/iptables";
              runAs = "root";
            }];
          }
          ```
        '';
      };
    };

  config =
    let
      cfg = config.services.reaction;
      generatedSettings = settingsFormat.generate "reaction.yml" cfg.settings;
      settingsFile = if cfg.settingsFile != null then cfg.settingsFile else generatedSettings;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion =
            (cfg.settings == { } && cfg.settingsFile != null)
            || (cfg.settings != { } && cfg.settingsFile == null);
          message = "You must choose between settings and settingsFile options";
        }
      ];

      users = lib.mkIf (!cfg.runAsRoot) {
        users.reaction = {
          isSystemUser = true;
          group = "reaction";
        };
        groups.reaction = { };
      };

      systemd.services.reaction = {
        enable = true;
        description = "Daemon to ban hosts that cause multiple authentication errors";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [
          pkgs.iptables
          pkgs.sudo
          "/run/wrappers"
        ];
        serviceConfig = {
          Type = "simple";
          User = lib.mkIf (!cfg.runAsRoot) "reaction";
          ExecStart = ''${cfg.package}/bin/reaction start -c ${settingsFile} ${
            lib.optionalString (cfg.loglevel != null) "-l ${cfg.loglevel}"
          }'';
          StateDirectory = "reaction";
          RuntimeDirectory = "reaction";
          WorkingDirectory = "/var/lib/reaction";
        };
      };

      environment.systemPackages = [ cfg.package ];
    };
}
