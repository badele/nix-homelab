# NetBox

![NetBox interface](netbox.png)

## 🔐 Secret

NetBox requires a secret key to securely hash passwords and HTTP cookies.

Generate a strong secret using the following command:

```bash
nix shell nixpkgs#openssl --command openssl rand -hex 50
```

Then add it to your `configuration/hosts/<HOSTNAME>/secrets.yml`:

```yaml
services:
  netbox:
    secret: <paste the output of the command above>
```

> 💡 Replace `<HOSTNAME>` with your actual host directory name.

---

## 👤 Superuser account

By default, NetBox does not create a user account during installation. You need
to manually create a **superuser** account.

Run the following command:

```bash
netbox-manage createsuperuser
```

You will be prompted to enter the credentials:

```text
Username (leave blank to use 'netbox'): admin
Email address: netbox@local.local
Password:
Password (again):
```

## Borg backup restoration

### The archive

```bash
sudo my-borg netbox list ${BORG_REPO_BASE}/./netbox
( cd / && sudo my-borg netbox extract ${BORG_REPO_BASE}/./netbox::badxps-netbox-2025-06-11T00:00:04)
```

### Netbox database

```bash
sudo -u postgres dropdb netbox sudo -u postgres createdb netbox
nix shell nixpkgs#postgresql --command sudo -u postgres pg_restore -Fd -d netbox /data/borgbackup/postgresql/netbox
```
