# Linkding

![Linkding interface](./imgs/linkding.png)

## Overview

Linkding is a self-hosted bookmark manager that is designed to be minimal and
fast. It provides a clean interface for managing bookmarks with tagging support
and search capabilities.

Key features:

- Clean and minimalist interface
- Full-text search
- Tag-based organization
- Browser extensions support
- Import/Export bookmarks
- Archive snapshots of bookmarks
- REST API

### Service Information

|                key | value                                 |
| -----------------: | ------------------------------------- |
|  installation type | **podman**                            |
| service management | `systemctl <COMMAND> podman-linkding` |
|               fqdn | `bonnes-adresses.ma-cabane.eu`        |
| application folder | `/data/podman/linkding`               |
|      backup folder | `/var/backup/linkding`                |
|             backup | see [borgbackup](./borgbackup.md)     |

### Configuration

The Linkding instance is configured in
[machines/houston/modules/linkding.nix](../machines/houston/modules/linkding.nix).

Key configuration parameters:

- **OAuth2 Integration**: Authelia for SSO
- **Storage**: SQLite database
- **Superuser**: `bookadmin` (auto-generated password)

## Initial Setup

After deploying Linkding with Clan, you can access it immediately:

1. Access the URL: `https://bonnes-adresses.ma-cabane.eu`
2. Log in using Authelia SSO
3. On first login, your account will be automatically created via OAuth

## Authelia Integration

Linkding integrates with [Authelia](./authelia.md) for Single Sign-On (SSO)
authentication using OpenID Connect.

### Prerequisites

- Authelia
- OAuth2 client secrets must be generated (done automatically by Clan)

## User Management

### Superuser Account

A superuser account is automatically created:

- **Username**: `bookadmin`
- **Password**: Auto-generated (see secrets)

To get the superuser password:

```bash
# On houston server
grep LD_SUPERUSER_PASSWORD /run/secrets/vars/linkding/envfile
```

**Note**: Most users should log in via Authelia OAuth. The superuser account is
mainly for administrative tasks or when OAuth is unavailable.

## Operations

### Import Bookmarks from Browser

To import bookmarks from Firefox or other browsers:

1. **Clean up broken links** (optional but recommended):
   - Install
     [Bookmarks Organizer](https://addons.mozilla.org/firefox/addon/bookmarks-organizer/)
   - Run the cleanup tool

2. **Export bookmarks using buku**:

   ```bash
   # Install buku
   nix shell nixpkgs#buku

   # Auto-import from browser
   buku --ai

   # Export with tags (based on folder names)
   buku -e bookmarks-with-tags.html
   ```

3. **Import to Linkding**:
   - Go to Linkding web interface
   - Navigate to Settings → Import
   - Upload the `bookmarks-with-tags.html` file
   - Tags will be preserved based on folder structure

### Update OAuth Secrets

If you need to regenerate OAuth2 secrets:

```bash
# On houston server
clan vars generate houston linkding

# Get the new secrets
clan vars get houston linkding/oauth2-client-secret
clan vars get houston linkding/digest-client-secret

# Restart both services
systemctl restart podman-linkding
systemctl restart authelia-main
```

Don't forget to update the secret in Authelia configuration!
