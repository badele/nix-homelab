# Homelab Administration

## Initial Setup (first time only)

See the [INIT-CLAN-SETUP](./INIT-CLAN-SETUP.md)

## Adding a New Machine

First, prepare the directory structure for the new machine:

```
just machine-add MACHINE-NAME
```

### Deploy New Machine

Insert the USB key created previously.

### Generating a Hardware Report

```shell
clan machines install "<MACHINE-NAME>" \
    --update-hardware-config nixos-facter \
    --phases kexec \
    --target-host "root@<IP-ADDRESS>"
```

### Disk configuration

List disko template

```shell
clan templates list
```

Configure partition

```shell
just nixos-apply-disko <MACHINE-NAME> btrfs-single-disk-subvolumes
just nixos-apply-disko <MACHINE-NAME> btrfs-single-disk-subvolumes wwn-0x5002538d428f282d
just nixos-apply-disko <MACHINE-NAME> luks-btrfs-single-disk-subvolumes
just nixos-apply-disko <MACHINE-NAME> luks-btrfs-single-disk-subvolumes wwn-0x5002538d428f282d
```

#### Host

Create or copy the `configuration.nix file on the `machines/<machine-name>/configuration.nix`,and specify the IP address
in `targetHost`.

#### Get Hardware Report

```bash
git add machines/<machine-name>
```

### Install

```bash
clan machines install "<MACHINE-NAME>" --target-host "<IP>"
```

### Update

```bash
just nixos-update "<MACHINE-NAME>"

# machine without internet
just nixos-update "<MACHINE-NAME>" --upload-inputs --host-key-check accept-new

# build on other host
just nixos-update "<MACHINE-NAME>" --build-host "<USERNAME@MACHINE-NAME>"
```
