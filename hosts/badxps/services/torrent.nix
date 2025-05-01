# Services:
# - bazarr: A companion application to Sonarr and Radarr: localhost:6767
# - flaresolverr: A proxy server for resolving captchas: localhost:8191
# - flood: A web interface for rtorrent : localhost:3000
# - jellyfin: A media server: localhost:8096
# - lidarr: A music collection manager for Usenet and BitTorrent users: localhost:8686
# - prowlarr: A fork of Sonarr to work with TV shows: localhost:9696
# - qbittorrent-nox:
#   - A torrent web UI: localhost:8080
#   - A torrent client: localhost:53545
# - radarr: A fork of Sonarr to work with movies: localhost:7878
# - readarr: A fork of Sonarr to work with ebooks: localhost:8787
# - sonarr: A PVR for Usenet and BitTorrent users: localhost:8989
{ config, pkgs, ... }:
let
  cfg = config.homelab.hosts.badxps;

  hostconfig = pkgs.stdenv.mkDerivation {
    name = "${config.networking.hostName}-hostconfig";
    src = ./../configfiles;
    installPhase = ''
      mkdir -p $out/
      cp -r $src/* $out/
    '';
  };

in
{
  # qBittorrent
  services.qbittorrent-nox = {
    enable = true;

    torrent.enableFirewall = false;
    ui.enableFirewall = false;
    torrent.port = cfg.params.torrent.clientPort;

    torrent.watcherFile = "${hostconfig}/qbittorrent/watched_folders.json";
  };

  # Cloudflare bot protection bypass
  virtualisation.oci-containers.containers = {
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:v3.3.21";
      ports = [ "8191:8191" ];
      environment = {
        LOG_LEVEL = "info";
        TZ = "Europe/Paris";
      };
      autoStart = true;
    };
  };

  # Flood web interface for qbittorrent
  services = {
    flood = {
      enable = true;
      host = "127.0.0.1";
      extraArgs = [ "--allowedpath /var/lib/qbittorrent-nox" ];
    };
  };
  systemd.services.flood = {
    serviceConfig = {
      SupplementaryGroups = [ "media" ];
      ReadWritePaths = [ "/var/lib/qbittorrent-nox" ];
    };
  };

  # flexget regularly checks the RSS feed and downloads new torrents
  services.flexget = {
    enable = true;
    user = "qbittorrent-nox";
    homeDir = "/var/lib/qbittorrent-nox";
    config = import ../secretfiles/flexget/config.nix;
  };

  # Indexers
  services.prowlarr = { enable = true; };

  # Ebooks
  services.readarr = {
    enable = true;
    user = "qbittorrent-nox";
    group = "media";
  };

  # Series
  services.sonarr = {
    enable = true;
    user = "qbittorrent-nox";
    group = "media";
  };

  # Jellyfin media server
  services.jellyfin = {
    enable = true;
    user = "qbittorrent-nox";
    group = "media";
  };
}
