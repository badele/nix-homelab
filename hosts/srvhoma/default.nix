##########################################################
# NIXOS (hosts)
##########################################################
{ inputs
, config
, pkgs
, lib
, ...
}:
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

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
    # ../../nix/nixos/roles/prometheus/exporter/node.nix
    # ../../nix/nixos/roles/prometheus/exporter/snmp.nix
    # ../../nix/nixos/roles/prometheus/exporter/smokeping.nix
  ];

  ####################################
  # Boot
  ####################################

  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
    ];
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
  };

  # xorg
  # videoDrivers = [ "intel" "i965" "nvidia" ];

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 8;
  };

  ####################################
  # Hardware
  ####################################

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true; ## If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  networking.hostName = "srvhoma";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
