# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # fileSystems."/" =
  #   {
  #     device = "zroot/private/root";
  #     fsType = "zfs";
  #   };
  #
  # fileSystems."/boot" =
  #   {
  #     device = "/dev/disk/by-uuid/7765-E4F4";
  #     fsType = "vfat";
  #   };
  #
  # fileSystems."/nix" =
  #   {
  #     device = "zroot/public/nix";
  #     fsType = "zfs";
  #   };
  #
  # fileSystems."/nix-homelab" =
  #   {
  #     device = "zroot/public/nix-homelab";
  #     fsType = "zfs";
  #   };
  #
  # fileSystems."/data" =
  #   {
  #     device = "zroot/private/data";
  #     fsType = "zfs";
  #   };
  #
  # fileSystems."/persist/host" =
  #   {
  #     device = "zroot/private/persist/host";
  #     fsType = "zfs";
  #   };
  #
  # fileSystems."/persist/user" =
  #   {
  #     device = "zroot/private/persist/user";
  #     fsType = "zfs";
  #   };
  #
  # swapDevices =
  #   [{ device = "/dev/disk/by-uuid/29ab3500-255c-4490-b5e9-7fad4da6b369"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
