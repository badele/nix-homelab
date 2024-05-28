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
    #inputs.hardware.nixosModules.dell-xps-15-9560
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    ../../nix/nixos/features/system/containers.nix
    ../../nix/nixos/features/system/virtualisation.nix

    # Desktop
    ../../nix/nixos/features/system/bluetooth.nix
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
  ];

  ####################################
  # Boot
  ####################################

  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
      "nouveau.blacklist=0"
      "acpi_osi=!"
      "acpi_osi=\"Windows 2015\""
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
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
    };
  };

  # xorg
  #videoDrivers = [ "intel" "i965" "nvidia" ];
  services.xserver.videoDrivers = [ "intel" "i965" "nvidia" ];
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
      user = "badele";
      session = "none+i3";
    };
  };

  ####################################
  # Hardware
  ####################################


  # Nvidia
  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;
  hardware.bumblebee.enable = true;
  hardware.bumblebee.pmMethod = "none"; # Needs nixos-unstable
  nixpkgs.config.nvidia.acceptLicense = true;
  # hardware.nvidia.optimus_prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true; ## If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  networking.hostName = "badxps";
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
