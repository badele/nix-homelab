# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  ####################################
  # Boot
  ####################################
  boot = {
    kernelPackages = pkgs.linuxPackages_6_6;
    kernelParams = [
      "i915.force_probe=3e9b"
      "mem_sleep_default=deep"
      "acpi_osi=!"
      ''acpi_osi="Windows 2015"''
      "acpi_backlight=vendor"
    ];

    blacklistedKernelModules = [ "nouveau" "bbswitch" ];

    kernelModules = [ "kvm-intel" ];
    #extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];
    supportedFilesystems = [ "zfs" "ntfs" ];
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

  ####################################
  # Pulseaudio
  ####################################

  services.pipewire.enable = false;
  hardware.pulseaudio = {
    enable = true;
    support32Bit =
      true; # # If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  ####################################
  # OpenGL
  ####################################

  # Enable OpenGL acceleration
  hardware.graphics.enable = true;

  # intel
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs;
      [
        vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
      ];
  };

  # Nvidia
  # hardware.nvidia = {
  #   open = false;
  #   # modesetting.enable = true;
  #   # powerManagement.enable = false;
  #   # powerManagement.finegrained = false;
  #   # nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.production; # 550.90.07
  #   #
  #   # # sudo lshw -c display
  #   # # Convert the hex result to decimal bus PCI, ex: 0e:00:00 to 14:0:0
  #   # prime = {
  #   #   intelBusId = "PCI:0:2:0";
  #   #   nvidiaBusId = "PCI:1:0:0";
  #   # };
  # };

  # hardware.bumblebee.enable = true;
  # hardware.bumblebee.pmMethod = "none"; # Needs nixos-unstable
  # hardware.nvidia.optimus_prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  ####################################
  # filesystems
  ####################################

  fileSystems."/" = {
    device = "zroot/private/root";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7765-E4F4";
    fsType = "vfat";
  };

  fileSystems."/nix" = {
    device = "zroot/public/nix";
    fsType = "zfs";
  };

  fileSystems."/nix-homelab" = {
    device = "zroot/public/nix-homelab";
    fsType = "zfs";
  };

  fileSystems."/data" = {
    device = "zroot/private/data";
    fsType = "zfs";
  };

  fileSystems."/persist/host" = {
    device = "zroot/private/persist/host";
    fsType = "zfs";
  };

  fileSystems."/persist/user" = {
    device = "zroot/private/persist/user";
    fsType = "zfs";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/29ab3500-255c-4490-b5e9-7fad4da6b369"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
