# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_5_15;
    kernelModules = [ ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      extraPools = [ "zroot" ];
    };

    loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # generic-extlinux-compatible.enable = true;
    };

    initrd = {
      availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sr_mod" ];
      supportedFilesystems = [ "zfs" ];
      kernelModules = [ ];
    };
  };

  fileSystems."/" =
    {
      device = "zroot/private/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    {
      device = "zroot/public/nix";
      fsType = "zfs";
    };

  fileSystems."/data" =
    {
      device = "zroot/private/data";
      fsType = "zfs";
    };

  fileSystems."/persist/host" =
    {
      device = "zroot/private/persist/host";
      fsType = "zfs";
    };

  fileSystems."/persist/user" =
    {
      device = "zroot/private/persist/user";
      fsType = "zfs";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "i686-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}

