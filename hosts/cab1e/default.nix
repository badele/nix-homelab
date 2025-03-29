# #########################################################
# NIXOS (hosts)
##########################################################
{ config, lib, pkgs, ... }:
let
  external_interface = "enp3s0";

  wireguard_network = "10.123.0.0/24";
  wireguard_private_ips = [ "10.123.0.1/32" ];
  wireguard_port = 54321;
  port_forwarding = 50000;
  peers = [{
    # badxps
    publicKey = "77u+Uy2Gt0j/Fu0GOw01Ex7B13c7HEfdYoANYP5rqEU=";
    allowedIPs = [ "10.123.0.2/32" ];
  }];

in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
  ];

  # Public peer server key
  # LQX7VSva7CZJmjmbGrFmG+37bS0PtTgy9Q6/15lIh08=
  sops.secrets = {
    "wireguard/private_peer" = { sopsFile = ../../hosts/cab1e/secrets.yml; };
  };

  ####################################
  # Boot
  ####################################
  boot = {
    kernelParams = [ "mem_sleep_default=deep" ];
    blacklistedKernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "btrfs" ];

    # Grub EFI boot loader
    loader = {
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiInstallAsRemovable = true;
        efiSupport = true;
        useOSProber = true;
      };
    };

    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv4.conf.default.forwarding" = true;
    };
  };

  ####################################
  # host profile
  ####################################
  hostprofile = { nproc = 2; };

  ####################################
  # Network
  ####################################

  # Host
  networking.hostName = "cab1e";
  networking.useDHCP = lib.mkDefault true;

  # Natting
  networking.nat = {
    enable = true;
    externalInterface = "enp3s0";
    internalInterfaces = [ "wg-cab1e" ];
    forwardPorts = [{
      sourcePort = port_forwarding;
      proto = "tcp";
      destination = "10.123.0.2:50000";
    }];

  };
  networking.firewall.allowedUDPPorts = [ wireguard_port port_forwarding ];

  # Wireguard
  networking.wireguard.enable = true;
  networking.wireguard.interfaces."wg-cab1e" = {
    privateKeyFile = config.sops.secrets."wireguard/private_peer".path;
    ips = wireguard_private_ips;
    listenPort = wireguard_port;

    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${wireguard_network} -o ${external_interface} -j MASQUERADE
    '';

    # This undoes the above command
    postShutdown = ''
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${wireguard_network} -o ${external_interface} -j MASQUERADE
    '';

    peers = peers;
  };

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
