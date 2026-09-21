# Homelab Administration

## Initial Setup (first time only)

See the [INIT-CLAN-SETUP](./INIT-CLAN-SETUP.md)

## Adding a New Machine

First, prepare the directory structure for the new machine:

```
just machine-add MACHINE-NAME
```

Create or copy `machines/<MACHINE-NAME>/configuration.nix`, then specify the
target IP address in `clan.core.networking.targetHost`.

Generate the machine variables:

```bash
clan vars generate <MACHINE-NAME>
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

#### Stage machine files

```bash
git add machines/<machine-name>
```

### Install Target Machine

Choose one installation path. Do not run both.

#### Local / USB target

Insert the USB key created previously, then gather the hardware report:

```shell
clan machines install "<MACHINE-NAME>" \
    --update-hardware-config nixos-facter \
    --phases kexec \
    --target-host "root@<IP-ADDRESS>"
```

Install NixOS:

```bash
clan machines install "<MACHINE-NAME>" --target-host "<IP>"
```

#### Hetzner Cloud target

Enter the development shell, ensure the `hetzner-homelab-token` Clan secret
exists, then create the server and install NixOS:

```bash
just hcloud-create-machine <MACHINE-NAME>
```

The Hetzner recipe creates the server, gets its public IPv4, then runs
`clan machines install` / `nixos-anywhere`. It does not create DNS records.

Do not run the local install step after `hcloud-create-machine`; it already
installs NixOS.

The machine name is required. Optional defaults are `cpx12`, `nbg1`,
`debian-12`, and SSH key `badele`. Override them when needed:

```bash
just hcloud-create-machine <MACHINE-NAME> cpx12 nbg1 debian-12 badele
```

Get the assigned public IPv4:

```bash
just hcloud-machine-ip <MACHINE-NAME>
```

If the assigned IP differs from the machine configuration, update
`machines/<MACHINE-NAME>/configuration.nix` and the `internet` role entry in
`machines/flake-module.nix`.

### Update

```bash
just nixos-update "<MACHINE-NAME>"

# machine without internet
just nixos-update "<MACHINE-NAME>" --upload-inputs --host-key-check accept-new

# build on other host
just nixos-update "<MACHINE-NAME>" --build-host "<USERNAME@MACHINE-NAME>"

# fallback when the target machine has a broken or incomplete network setup
# Example for constellation: build on gagarin, upload the flake inputs,
# and force the LAN target instead of any alternate SSH transport.
just nixos-update constellation --target-host root@192.168.254.1 --build-host badele@192.168.254.179 --upload-inputs --host-key-check accept-new
```
