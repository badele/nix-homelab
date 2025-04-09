# #########################################################
# NIXOS (hosts)
##########################################################
{ config, lib, pkgs, ... }:
let

  cfg = config.homelab.hosts.badxps;
  hostconfiguration = {
    description = "Infomaniak cab1e instance";
    dnsalias = null;
    icon =
      "https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png";
    ipv4 = "10.123.0.2";
    os = "NixOS";
    parent = "internet";
    roles = [ ];
    wg = null;
    zone = "infomaniak";

    params = {
      nat.public.interface = "enp3s0";

      wireguard = {
        interface = "wg-cab1e";
        serverIPs = [ "10.123.0.1/32" ];
        listenPort = 54321;
        peers = [{
          # badxps
          publicKey = "77u+Uy2Gt0j/Fu0GOw01Ex7B13c7HEfdYoANYP5rqEU=";
          allowedIPs = [ "${cfg.params.torrent.clientIP}/32" ];
        }];
      };

      torrent = {
        clientIP = "10.123.0.2";

        interface = "wg-cab1e";
        clientWebPort = 8080;
        clientPort = 53545;
      };
    };
  };

in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix

    # homelab modules
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/modules/nixos/homelab
    ../../nix/nixos/features/commons
  ];

  ####################################
  # Host Configuration
  ####################################

  homelab.hosts.badxps = hostconfiguration;
  hostprofile = { nproc = 2; };

  ####################################
  # Network
  ####################################

  networking.hostName = "cab1e";
  networking.useDHCP = lib.mkDefault true;

  networking = {
    # Wireguard
    wireguard = {
      enable = true;
      interfaces."${cfg.params.wireguard.interface}" = {
        privateKeyFile = config.sops.secrets."wireguard/private_peer".path;
        ips = cfg.params.wireguard.serverIPs;
        listenPort = cfg.params.wireguard.listenPort;

        peers = cfg.params.wireguard.peers;
      };
    };

    # Firewall
    nftables.enable = true;
    firewall = {
      enable = true;
      logRefusedPackets = true;
      logReversePathDrops = true;
      logRefusedConnections = true;

      interfaces = {
        "${cfg.params.nat.public.interface}" = {
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ cfg.params.wireguard.listenPort ];
        };
        "${cfg.params.wireguard.interface}" = {
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ ];
        };
      };
    };

    # Nat
    nat = {
      enable = true;
      internalIPs = [ "${cfg.params.torrent.clientIP}/32" ];
      internalInterfaces = [ cfg.params.torrent.interface ];
      externalInterface = cfg.params.nat.public.interface;

      forwardPorts = [
        {
          sourcePort = cfg.params.torrent.clientPort;
          destination = "${cfg.params.torrent.clientIP}:${
              toString cfg.params.torrent.clientPort
            }";
          proto = "tcp";
        }
        {
          sourcePort = cfg.params.torrent.clientPort;
          destination = "${cfg.params.torrent.clientIP}:${
              toString cfg.params.torrent.clientPort
            }";
          proto = "udp";
        }
      ];
    };
  };

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };
  environment.systemPackages = with pkgs; [ ];

  ####################################
  # Secrets
  ####################################

  # Public peer server key
  # LQX7VSva7CZJmjmbGrFmG+37bS0PtTgy9Q6/15lIh08=
  sops.secrets = {
    "wireguard/private_peer" = { sopsFile = ../../hosts/cab1e/secrets.yml; };
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";

}
