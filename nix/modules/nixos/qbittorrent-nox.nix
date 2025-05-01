{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.qbittorrent-nox;
in {
  options.services.qbittorrent-nox = {
    enable = lib.mkEnableOption "qbittorrent-nox";

    package = lib.mkPackageOption pkgs "qbittorrent-nox" { };

    group = mkOption {
      type = types.str;
      default = "media";
      description = ''
        Group under which qbittorrent-nox runs.
      '';
    };

    ui.enableFirewall = lib.mkOption {
      description = "Add the web UI port to firewall";
      type = lib.types.bool;
      default = false;
    };
    ui.port = lib.mkOption {
      description = "Web UI port";
      type = lib.types.port;
      default = 8080;
    };

    torrent.enableFirewall = lib.mkOption {
      description = "Add the torrenting port to firewall";
      type = lib.types.bool;
      default = true;
    };
    torrent.port = lib.mkOption {
      description = "Torrenting port";
      type = with lib.types; nullOr port;
      default = null;
    };
    torrent.watcherFile = lib.mkOption {
      description = "JSON watch files";
      type = lib.types.path;
      default = "";
    };
  };

  config = mkIf cfg.enable {

    users.users.qbittorrent-nox = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/qbittorrent-nox";
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/incomplete/ebooks' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/incomplete/films' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/incomplete/series' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/complete' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/watch/ebooks' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/watch/films' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/watch/series' 0775 qbittorrent-nox ${cfg.group} - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/data/logs' 0775 qbittorrent-nox ${cfg.group} - -"
      "L+ /var/lib/qbittorrent-nox/qBittorrent/config/watched_folders.json - - - - ${cfg.torrent.watcherFile}"
    ];

    networking.firewall.allowedTCPPorts =
      lib.optional (cfg.torrent.enableFirewall && cfg.torrent.port != null)
        cfg.torrent.port ++ lib.optional cfg.ui.enableFirewall cfg.ui.port;
    networking.firewall.allowedUDPPorts =
      lib.optional (cfg.torrent.enableFirewall && cfg.torrent.port != null)
        cfg.torrent.port;

    systemd.services.qbittorrent-nox = {
      description = "qBittorrent-nox service";
      documentation = [ "man:qbittorrent-nox(1)" ];
      after = [ "network.target" "systemd-tmpfiles-setup.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "qbittorrent-nox";
        Group = cfg.group;
        WorkingDirectory = "/var/lib/qbittorrent-nox";

        ExecStart = ''
          ${cfg.package}/bin/qbittorrent-nox --confirm-legal-notice ${
            lib.optionalString (cfg.torrent.port != null)
            "--torrenting-port=${toString cfg.torrent.port}"
          } --webui-port=${
            toString cfg.ui.port
          } --profile=/var/lib/qbittorrent-nox
        '';

        UMask = "0002";
      };
    };
  };
}
