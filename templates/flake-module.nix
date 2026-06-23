{
  ...
}:
{
  flake.clan.templates.disko.btrfs-single-disk-subvolumes = {
    path = ./disko/btrfs-single-disk-subvolumes;
    description = "Single disk schema with Btrfs subvolumes and btrbk snapshots";
  };

  flake.clan.templates.disko.luks-btrfs-single-disk-subvolumes = {
    path = ./disko/luks-btrfs-single-disk-subvolumes;
    description = "Single disk schema with LUKS encryption and Btrfs subvolumes";
  };
}
