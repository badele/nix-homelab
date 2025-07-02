{ inputs, config, pkgs, lib, ... }:
let
  cfg = config.homelab.hosts.badxps;
  hostconfiguration = {
    description = "Dell XPS 9570 Latop";
    roles = [ "coredns" "linkding" "netbox" "virtualization" ];
    dnsalias = [
      "flood"
      "home"
      "jellyfin"
      "links"
      "netbox"
      "prowlarr"
      "radarr"
      "readarr"
      "sonarr"
    ];

    icon =
      "https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png";
    ipv4 = "192.168.254.114";
    os = "NixOS";
    nproc = 12;

    autologin = {
      user = "badele";
      session = "none+i3";
    };

    parent = "router-ladbedroom";
    zone = "homeoffice";

    params = {
      wireguard = {
        endpoint = "84.234.31.97:54321";
        privateIPs = [ "10.123.0.2/24" ];
        publicKey = "LQX7VSva7CZJmjmbGrFmG+37bS0PtTgy9Q6/15lIh08=";
      };

      torrent = {
        interface = "wg-cab1e";
        clientWebPort = 8080;
        clientPort = 53545;
      };
    };
  };
in {
  imports = [ ];

  homelab.hosts.badxps = hostconfiguration;
}
