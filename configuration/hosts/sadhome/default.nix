# #########################################################
# NIXOS (hosts)
##########################################################
{ inputs, config, pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix
    ../sadele.nix

    # Commons
    ../../nix/modules/nixos/homelab
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/system/containers.nix

    # Desktop
    ../../nix/nixos/features/desktop/wm/xorg/gdm.nix

    # Printer
    ../../nix/nixos/features/system/printer.nix
  ];

  ####################################
  # Boot
  ####################################

  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
      "nouveau.blacklist=0"
      "acpi_osi=!"
      ''acpi_osi="Windows 2015"''
      "acpi_backlight=vendor"
    ];

    blacklistedKernelModules = [ "nouveau" "bbswitch" ];

    kernelModules = [ "kvm-intel" ];
    #extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];
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
      kernelModules = [ ];
    };
  };

  # xorg
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.opengl.enable = true;
  #hardware.nvidia.package = boot.kernelPackages.nvidiaPackages.stable;
  #hardware.nvidia.modesetting.enable = true;

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 12;
    autologin = {
      user = "sadele";
      session = "gnome";
    };
  };
  ####################################
  # Hardware
  ####################################

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit =
      true; # # If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  networking.hostName = "sadhome";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { dconf.enable = true; };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "22.11";
}
