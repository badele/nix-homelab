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

    # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9530
    inputs.hardware.nixosModules.dell-xps-15-9530-intel
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    ../../nix/nixos/features/system/containers.nix

    # Desktop
    ../../nix/nixos/features/system/bluetooth.nix
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix
  ];

  ####################################
  # Boot
  ####################################

  boot = {
    # kernelParams = [ # See dell-xps-15-9530
    #   "mem_sleep_default=deep"
    #   "nouveau.blacklist=0"
    #   "acpi_osi=!"
    #   "acpi_osi=\"Windows 2015\""
    #   "acpi_backlight=vendor"
    # ];

    # blacklistedKernelModules = See dell-xps-15-9530
    # extraModulePackages = See dell-xps-15-9530

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
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ "zfs" ];
    };
  };

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 20;
    autologin = {
      user = "badele";
      session = "none+i3";
    };
  };

  ####################################
  # Hardware
  ####################################
  videoDrivers = [ "intel" "i965" "nvidia" ];


  # Nvidia
  # hardware.opengl.enable = true;
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  # hardware.nvidia.modesetting.enable = true;
  # hardware.bumblebee.enable = See dell-xps-15-9530
  # hardware.bumblebee.pmMethod = See dell-xps-15-9530

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true; ## If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  networking.hostName = "b4d14";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = {
    dconf.enable = true;
  };

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
  system.stateVersion = "22.11";
}
