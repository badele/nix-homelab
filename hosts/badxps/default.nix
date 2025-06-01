# #########################################################
# NIXOS (hosts)
##########################################################
{ inputs, config, pkgs, lib, ... }:
let
  cfg = config.homelab.hosts.badxps;
  hostconfiguration = {
    description = "Dell XPS 9570 Latop";
    dnsalias = [
      "flood"
      "home"
      "jellyfin"
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
    roles = [ "virtualization" "coredns" ];
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
in
{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-9570-intel
    ./hardware-configuration.nix

    # Modules
    ../../nix/modules/nixos/homelab
    ../../nix/modules/nixos/qbittorrent-nox.nix

    # Users account
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/system/containers.nix

    # ../../nix/nixos/features/virtualisation/incus.nix
    # ../../nix/nixos/features/virtualisation/libvirt.nix

    # Desktop
    ../../nix/nixos/features/system/bluetooth.nix
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix

    # Services
    ./services/homepage.nix
    ./services/netbox.nix
    ./services/torrent.nix
    ./services/traefik.nix

    # # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
  ];

  ####################################
  # Host Configuration
  ####################################

  homelab.hosts.badxps = hostconfiguration;

  users.groups.media = { };

  ####################################
  # Boot
  ####################################

  # Docker
  virtualisation.docker.storageDriver = "zfs";

  nixpkgs.config = {
    # allowBroken = true;
    # nvidia.acceptLicense = true;
  };

  # xorg
  # services.xserver.videoDrivers = [ "intel" "i965" "nvidia" ];
  services.xserver.videoDrivers = [ "modesetting" ];
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.opengl.enable = true;
  #hardware.nvidia.package = boot.kernelPackages.nvidiaPackages.stable;
  #hardware.nvidia.modesetting.enable = true;

  ####################################
  # Network
  ####################################

  networking.hostName = "badxps";
  networking.useDHCP = lib.mkDefault true;

  networking = {
    wireguard = {
      enable = true;
      interfaces = {
        wg-cab1e = {
          mtu = 1384; # Permet de réduire la taille des paquets
          ips = cfg.params.wireguard.privateIPs;
          privateKeyFile =
            config.sops.secrets."services/wireguard/private_peer".path;

          postSetup = ''
            ${pkgs.iproute2}/bin/ip route add default via 10.123.0.2
          '';

          peers = [{
            publicKey = cfg.params.wireguard.publicKey;
            allowedIPs = [ "0.0.0.0/0" ]; # Tout le trafic passe par le VPN
            endpoint = cfg.params.wireguard.endpoint;
            persistentKeepalive = 25; # Permet de maintenir la connexion active
          }];
        };
      };
    };

    # Firewall
    firewall = {
      package = pkgs.iptables-nftables-compat;
      enable = true;
      logRefusedPackets = true;
      logReversePathDrops = true;
      logRefusedConnections = true;

      interfaces = {
        "${cfg.params.torrent.interface}" = {
          allowedTCPPorts = [ cfg.params.torrent.clientPort ];
          allowedUDPPorts = [ cfg.params.torrent.clientPort ];
        };
      };
    };
  };

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { dconf.enable = true; };
  environment.systemPackages = [ ];

  ####################################
  # Secrets
  ####################################

  sops.secrets = {
    "spotify/user" = {
      mode = "0400";
      owner = config.users.users.badele.name;
    };

    "spotify/password" = {
      mode = "0400";
      owner = config.users.users.badele.name;
    };

    "services/wireguard/private_peer" = {
      sopsFile = ../../hosts/badxps/secrets.yml;
    };
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "25.05";
}
