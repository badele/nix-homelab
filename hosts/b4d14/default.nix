# #########################################################
# NIXOS (hosts)
##########################################################
{ inputs, config, pkgs, lib, ... }:
let
  cfg = config.homelab.hosts.b4d14;
  hostconfiguration = {
    description = "Dell XPS 9560 Latop";
    icon =
      "https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png";
    ipv4 = "192.168.254.124";
    os = "NixOS";
    nproc = 20;

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
in {
  imports = [
    # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9520
    inputs.hardware.nixosModules.dell-xps-15-9520
    ./hardware-configuration.nix

    # Modules
    ../../nix/modules/nixos/homelab

    # Users account
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/system/containers.nix

    # Desktop
    ../../nix/nixos/features/system/bluetooth.nix
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix
  ];

  ####################################
  # Host Configuration
  ####################################

  homelab.hosts.b4d14 = hostconfiguration;

  ####################################
  # Boot
  ####################################

  boot = {
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      extraPools = [ "zroot" ];
    };

    # EFI boot loader
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ "zfs" ];
    };
  };

  ####################################
  # Network
  ####################################

  networking.hostName = "b4d14";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Hardware
  ####################################
  # videoDrivers = [ "intel" "i965" "nvidia" ];

  # Nvidia
  # hardware.opengl.enable = true;
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  # hardware.nvidia.modesetting.enable = true;
  # hardware.bumblebee.enable = See dell-xps-15-9530
  # hardware.bumblebee.pmMethod = See dell-xps-15-9530

  # Pulseaudio
  services.pipewire.enable = false;
  hardware.pulseaudio = {
    enable = true;
    support32Bit =
      true; # # If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  virtualisation.docker = { storageDriver = "zfs"; };

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
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
