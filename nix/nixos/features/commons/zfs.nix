{ lib, pkgs, ... }: {
  services.zfs = {
    autoSnapshot.enable = true;
    autoSnapshot.monthly = 1;
    autoScrub.enable = true;
  };
  boot.kernelPackages = lib.mkDefault pkgs.zfs.latestCompatibleLinuxPackages;

  # ZFS already has its own scheduler. Without this my(@Artturin) computer froze for a second when i nix build something.
  # Source: https://github.com/TUM-DSE/doctor-cluster-config/blob/master/modules/zfs.nix
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';
}

