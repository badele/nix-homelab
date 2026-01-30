# Homelab Administration

## Initial Setup (first time only)

### Create Clan USB Installer

> [!NOTE]
> Skip this step if you have already installed one machine

Get the USB device path with the following command:

```bash
lsblk
```

Create the bootable USB installer:

```bash
#clan flash list keymaps
#clan flash list languages

export USBDISK="/dev/sda"

ssh-add -L | head -n 1 > /tmp/ssh_key.pub
clan flash write --flake git+https://git.clan.lol/clan/clan-core \
  --ssh-pubkey /tmp/ssh_key.pub \
  --keymap fr \
  --language fr_FR.UTF-8 \
  --disk main ${USBDISK} \
  flash-installer
```

### Key Initialization

> [!NOTE]
> Skip this step if you have already installed one machine

Before administering a host, you need to create age public/private keys.

If you don't have an [age](https://github.com/FiloSottile/age) key, you can
create one with the following command:

```bash
clan secrets key generate
```

#### Add Your Public Key

You can add your public key to your user keyring:

```bash
clan secrets users add badele --age-key <your_public_key>
```

## Adding a New Machine

First, prepare the directory structure for the new machine:

```
machines
└─ <MACHINE-NAME>
   ├─ configuration.nix
   └─ disko.nix
```

### Deploy New Machine

Insert the USB key created previously.

#### Host

In the `machines/<machine-name>/configuration.nix` file, specify the IP address
in `targetHost`.

#### Disk Device ID

Connect as `root` to the previously obtained IP address and retrieve the disk ID
with the following command:

```bash
ssh "root@<HOST-IP>" 'lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT'
```

Example output:

```
NAME   ID-LINK                             FSTYPE   SIZE MOUNTPOINT
sda    wwn-0x5000000123456789                     476.9G
├─sda1 wwn-0x5000000123456789-part1        vfat     100M
├─sda2 wwn-0x5000000123456789-part2                  16M
├─sda3 wwn-0x5000000123456789-part3        ntfs   475.7G
└─sda4 wwn-0x5000000123456789-part4        ntfs     1.2G
sdb    usb-_PHILIPS_USB_48333095-0:0               29.3G
├─sdb1 usb-_PHILIPS_USB_48333095-0:0-part1            1M
├─sdb2 usb-_PHILIPS_USB_48333095-0:0-part2 vfat     512M /boot
└─sdb3 usb-_PHILIPS_USB_48333095-0:0-part3 f2fs    28.8G /
```

Update the `machines/<machine-name>/disko.nix` file to set the `diskId`
variable:

```nix
diskId = "wwn-0x5000000123456789";
```

#### Get Hardware Report

```bash
git add machines/<machine-name>/configuration.nix
git add machines/<machine-name>/disko.nix
clan machines update-hardware-config "<MACHINE-NAME>"
```

### Install

```bash
clan machines install "<MACHINE-NAME>" --target-host "<IP>"
```
