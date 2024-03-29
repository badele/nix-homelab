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
    kernelPackages = pkgs.linuxPackages_rpi4;
    kernelModules = [ ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      extraPools = [ "zroot" ];
    };

    loader = {
      #systemd-boot.enable = true;
      grub.enable = false;
      # generic-extlinux-compatible.enable = true;
      # efi.canTouchEfiVariables = true;

      raspberryPi = {
        enable = true;
        version = 4;
      };
    };

    initrd = {
      availableKernelModules = [ "xhci_pci" "usbhid" "uas" "usb_storage" ];
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

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # SDR
  hardware.rtl-sdr.enable = true;
  networking.firewall.allowedTCPPorts = [
    1234
    1235
  ];

}
