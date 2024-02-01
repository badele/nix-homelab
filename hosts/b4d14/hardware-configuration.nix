# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sr_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "zroot/private/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C178-A6D4";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "zroot/public/nix";
      fsType = "zfs";
    };

  fileSystems."/nix-homelab" =
    { device = "zroot/public/nix-homelab";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "zroot/private/data";
      fsType = "zfs";
    };

  fileSystems."/persist/host" =
    { device = "zroot/private/persist/host";
      fsType = "zfs";
    };

  fileSystems."/persist/user" =
    { device = "zroot/private/persist/user";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/3b4aaec1-ae97-468b-8203-ae2e0757a4ad"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}