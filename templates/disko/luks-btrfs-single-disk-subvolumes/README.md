---
description = "Single disk schema with LUKS encryption, Btrfs subvolumes, and automated btrbk snapshots"
---

This schema defines a GPT-based single-disk layout with a LUKS-encrypted root container and [btrfs-subvolume](https://www.man7.org/linux//man-pages/man8/btrfs-subvolume.8.html) for organized data management.

### Disk Overview

- Name: `main-{{uuid}}`
- Device: `{{mainDisk}}`

### Partitions

1. **BIOS Boot Partition**
   - Provides compatibility for MBR booting on GPT disks.
   - Size: `1M`
   - Type: `EF02`

2. **EFI System Partition (ESP)**
   - Size: `500M`
   - Type: `EF00`
   - Filesystem: `vfat`
   - Mount Point: `/boot`
   - Options: `umask=0077` (restrictive permissions for security).

3. **Encrypted Root Partition (LUKS)**
   - Size: Remaining disk space (`100%`).
   - Container: `luks`.
   - Mapping name: `cryptroot`.
   - Contains: a `btrfs` filesystem labeled `root` with subvolumes:
     - `@root`: Mounted at `/` (system root).
     - `@nix`: Mounted at `/nix`, with `compress=zstd` and `noatime`.
     - `@home`: Mounted at `/home`, with `compress=zstd`.

### Encryption Notes

- Root data is encrypted at rest with LUKS.
- `/boot` remains unencrypted for bootloader/kernel/initrd access.
- During boot, initrd unlocks `cryptroot` before mounting Btrfs subvolumes.

### Snapshot Management (btrbk)

The configuration includes automated local snapshots via [`btrbk`](https://digint.ch/btrbk/doc/readme.html) to ensure recovery options.

- Frequency: Every 2 hours (`0/2:00`).
- Retention:
  - `/nix`: 16 hourly, 7 daily, and 2 weekly snapshots.
  - `/home`: 16 hourly, 7 daily, 3 weekly, and 2 monthly snapshots.
- Minimum Guarantee: At least 3 days of snapshots are always preserved.
