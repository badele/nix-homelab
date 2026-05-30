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

export USBDISK="/dev/sdx"

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

Store your age key on your admin desktop to

```bash
mkdir -p ~/.config/sops/age
pass show nix-homelab/age/$USERNAME > ~/.config/sops/age/keys.txt
```

## Adding a New Machine

First, prepare the directory structure for the new machine:

```
just machine add MACHINE-NAME
```

### Deploy New Machine

Insert the USB key created previously.

#### Wifi configuration

```shell
iwctl
```

```text
# Identify your network device.
device list

# Replace 'wlan0' with your wireless device name
# Find your Wi-Fi SSID.
station wlan0 scan
station wlan0 get-networks

# Replace your_ssid with the Wi-Fi SSID
# Connect to your network.
station wlan0 connect your_ssid

# Verify you are connected
station wlan0 show
```

Press **CTRL+d**

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
just nixos-apply-disko airlock luks-btrfs-single-disk-subvolumes
just nixos-apply-disko airlock luks-btrfs-single-disk-subvolumes /dev/disk/by-id/wwn-0x5002538d428f282d
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
