{ config, ... }:
let cfg = config.homelab.hosts.badxps;

in {

  services = {
    bazarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    readarr.enable = true;
    sonarr.enable = true;

    qbittorrent-nox = {
      enable = true;

      torrent.enableFirewall = false;
      ui.enableFirewall = false;
      torrent.port = cfg.params.torrent.clientPort;
    };
  };

  systemd.services.flood = {
    serviceConfig = {
      SupplementaryGroups = [ "qbittorrent-nox" ];
      ReadWritePaths = [ "/var/lib/qbittorrent-nox" ];
    };
  };

  services = {
    flood = {
      enable = true;
      host = "127.0.0.1";
      extraArgs = [ "--allowedpath /var/lib/qbittorrent-nox" ];
    };
  };
}
