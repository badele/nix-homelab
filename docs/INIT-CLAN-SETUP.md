# Homelab Administration

## Initial Setup (first time only)

### Create Clan USB Installer

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
