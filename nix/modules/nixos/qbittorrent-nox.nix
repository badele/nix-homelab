{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.qbittorrent-nox;
in {
  options.services.qbittorrent-nox = {
    enable = lib.mkEnableOption "qbittorrent-nox";

    package = lib.mkPackageOption pkgs "qbittorrent-nox" { };

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
  };

  config = mkIf cfg.enable {

    users.users.qbittorrent-nox = {
      isSystemUser = true;
      group = "qbittorrent-nox";
      home = "/var/lib/qbittorrent-nox";
    };
    users.groups.qbittorrent-nox = { };

    systemd.tmpfiles.rules = [
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/completed' 0755 qbittorrent-nox qbittorrent-nox - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/downloads/incomplete' 0755 qbittorrent-nox qbittorrent-nox - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/watch' 0755 qbittorrent-nox qbittorrent-nox - -"
      "d '/var/lib/qbittorrent-nox/qBittorrent/data/logs' 0755 qbittorrent-nox qbittorrent-nox - -"
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
        Group = "qbittorrent-nox";
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
