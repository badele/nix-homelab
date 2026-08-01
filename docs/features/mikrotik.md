<!-- BEGIN SECTION feature_informations file=./.templates/feature_mikrotik.html -->

<div class="feature-detail">
  <h1 id="mikrotik">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/mikrotik.png" width="64" height="64" alt="MikroTik" style="vertical-align: middle; margin-right: 10px;"/>
    MikroTik
  </h1>
  <h2>Basic Information</h2>
  <p>MikroTik RouterOS management helpers</p>
  <table>
    <tbody>
      <tr>
        <th>Category</th>
        <td>
<a href="/docs/all-features.md#core-services">Core Services</a>
        </td>
      </tr>
      <tr>
        <th>Platform</th>
        <td>nixos</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://mikrotik.com/">https://mikrotik.com/</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/mikrotik">modules/features/mikrotik</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is MikroTik?

[MikroTik](https://mikrotik.com/) provides RouterOS, a network operating system
used on MikroTik routers and switches. In this homelab, the MikroTik feature
adds NixOS-managed helpers for backing up RouterOS configurations.

The backup helper creates both a binary RouterOS backup and a text export, then
encrypts both files locally with age.

## Why Use MikroTik?

> Encrypted RouterOS configuration backups managed from NixOS

**Key benefits:**

- **Dedicated Account**: Uses a local NixOS `mikrotik` user and a RouterOS
  `backup` account
- **Encrypted Backups**: Stores `.backup` and `.rsc` files encrypted with age
- **Per-Router History**: Keeps backups under one directory per router
- **Retention Policy**: Keeps only the configured number of local backup pairs
- **Manual Restore Helpers**: Decrypts and copies restore files without loading
  them automatically on the router

## Configuration

### NixOS Setup

Enable the MikroTik feature on the machine that collects router backups:

```nix
homelab.features.mikrotik = {
  enable = true;
  backup = true;

  routers = [
    {
      name = "mkt254";
      host = "192.168.240.254";
    }
    {
      name = "mkt253";
      host = "192.168.240.253";
    }
    {
      name = "mkt252";
      host = "192.168.240.252";
    }
  ];
};
```

The feature creates a local system user named `mikrotik`, a dedicated SSH key,
and a dedicated age key.

Get the SSH public key that must be installed on each router:

```bash
just clan-vars-get <MACHINE> mikrotik/ssh.id_ed25519.pub
```

### RouterOS User Setup

Create the dedicated RouterOS user and group:

```routeros
/user group add name=backup policy=ssh,ftp,read,write,policy,test,password,sensitive
/user add name=backup group=backup comment="nix-homelab backup account"
```

### SSH Key Registration

From a sysops workstation, fetch the public key for the NixOS host that runs
`mikrotik-backup`, then copy and import it on the router.

```bash
HOSTNAME=constellation
ROUTER=192.168.240.254
KEY_FILE=nixos_${HOSTNAME}_mikrotik.pub

just clan-vars-get "$HOSTNAME" mikrotik/ssh.id_ed25519.pub > "/tmp/$KEY_FILE"
scp "/tmp/$KEY_FILE" "admin@$ROUTER:$KEY_FILE"
ssh -n "admin@$ROUTER" "/user ssh-keys import public-key-file=$KEY_FILE user=backup"
rm -f "/tmp/$KEY_FILE"
```

To test the private key from a sysops workstation:

```bash
HOSTNAME=constellation
ROUTER=192.168.240.254
KEY_FILE=/tmp/nixos_${HOSTNAME}_mikrotik_ed25519

just clan-vars-get "$HOSTNAME" mikrotik/ssh.id_ed25519 > "$KEY_FILE"
chmod 600 "$KEY_FILE"

ssh -i "$KEY_FILE" -o IdentitiesOnly=yes backup@"$ROUTER"

rm -f "$KEY_FILE"
```

### Backup Operations

Backups are stored under:

```text
/data/backup/mikrotik/<router>/
```

Each run creates two encrypted files:

```text
<timestamp>.backup.age
<timestamp>.rsc.age
```

Run a manual backup:

```bash
systemctl start mikrotik-backup
```

Inspect the last execution:

```bash
systemctl status mikrotik-backup
journalctl -u mikrotik-backup
```

The feature also exposes service aliases:

```bash
@service-mikrotik-backup-start
@service-mikrotik-backup-status
@service-mikrotik-backup-journal
```

The timer runs daily at 03:30 by default and keeps the 30 newest encrypted
backup/export files per router.

### Restore Operations

Run the restore helpers from the NixOS host that runs `mikrotik-backup`. The
helpers must be run as the local `mikrotik` user. From `root`, open a shell
with:

```bash
su mikrotik -s /run/current-system/sw/bin/bash
```

List encrypted backups for a router:

```bash
@mikrotik-list-backup-for-router mkt254
```

The command prints full paths:

```text
  backup: /data/backup/mikrotik/mkt254/20260801T142235Z.backup.age
  export: /data/backup/mikrotik/mkt254/20260801T142235Z.rsc.age
```

Copy a backup pair to a router. Pass the absolute path of either file from the
encrypted pair:

```bash
@mikrotik-restore-backup-file-for-router \
  /data/backup/mikrotik/mkt254/20260801T142235Z.backup.age \
  192.168.240.254
```

The helper uses:

```text
/run/secrets/vars/mikrotik/age.key
/run/secrets/vars/mikrotik/ssh.id_ed25519
```

It does not run the restore command automatically.

After the files are copied, check them on the router:

```routeros
/file print where name~"restored-nix-homelab-20260801T142235Z"
```

Restore the binary backup:

```routeros
/system backup load name=restored-nix-homelab-20260801T142235Z.backup
```

The binary backup is the complete RouterOS restore path. It replaces the router
configuration and reboots the router.

The text export can be inspected or imported separately:

```routeros
/import file-name=restored-nix-homelab-20260801T142235Z.rsc
```

## Learn More

- [MikroTik Official Website](https://mikrotik.com/)
- [RouterOS Configuration Management](https://help.mikrotik.com/docs/spaces/ROS/pages/328155/Configuration+Management)
