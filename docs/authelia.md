# Authelia - Authentication & Authorization Server

<p align="center">
  <img src="./imgs/authelia.png" alt="Authelia successful authentication">
</p>

## What is Authelia?

[Authelia](https://www.authelia.com/) is an open-source authentication and
authorization server that provides 2-factor authentication and single sign-on
(SSO) for your applications via a web portal.

It acts as a security gateway between your applications and users, providing a
unified authentication layer across all your services.

## Why Use Authelia?

> Secure access to your applications with enterprise-grade authentication

**Key benefits:**

- **Single Sign-On (SSO)**: Log in once, access all your applications
- **Enhanced Security**: Two-factor authentication (2FA) with TOTP, WebAuthn
- **Centralized Access Control**: Manage access policies for all applications in
  one place
- **LDAP Integration**: Use LLDAP for user management instead of flat files
- **Flexible Policies**: Define access rules based on users, groups, networks,
  and resources
- **Session Management**: Control session lifetime and behavior across
  applications

## Key Features

### 1. Single Sign-On (SSO) via OpenID Connect

Authelia provides SSO authentication for multiple applications. Log in once and
access all integrated services without re-authentication.

### 2. Two-Factor Authentication (2FA)

Multiple 2FA methods supported:

- Time-based One-Time Passwords (TOTP)
- WebAuthn/U2F security keys

### 3. LDAP Integration

Integration with [LLDAP](./lldap.md) for user management through a web
interface, avoiding command-line user management.

### 4. Flexible Access Control Policies

Define granular access rules:

- Per-user or per-group access
- Network-based rules (internal vs external)
- Resource-specific policies
- Time-based access restrictions

## Service Information

|                key | value                               |
| -----------------: | ----------------------------------- |
|  installation type | **NixOS native service**            |
| service management | `systemctl <COMMAND> authelia-main` |
|           web port | 9091                                |
|               fqdn | `douane.ma-cabane.eu`               |
| application folder | `/var/lib/authelia-main`            |
|    database folder | `/var/lib/authelia-main/db.sqlite3` |
|             backup | see [borgbackup](./borgbackup.md)   |

### Configuration

The Authelia instance is configured in
[machines/houston/modules/authelia.nix](../machines/houston/modules/authelia.nix).

Key configuration parameters:

- **Base DN**: `dc=homelab,dc=lan`
- **LDAP Backend**: LLDAP (port 3890)
- **Session Domain**: `ma-cabane.eu`
- **Storage**: SQLite database
- **SMTP**: Gmail with application password

## User Management

User management is **NOT** done directly in Authelia. Instead, I use
[LLDAP](./lldap.md) for user management.

Why LLDAP instead of Authelia's built-in user database?

- Authelia's file-based user management
  (`/var/lib/authelia-main/users_database.yml`) requires using command-line
  scripts, which is not practical
- LLDAP provides a lightweight LDAP service with a web interface
- Easy to manage users and groups through a web UI
- Standard LDAP protocol for integration with other services

See [LLDAP documentation](./lldap.md) for details on user management.

## Integration

### Integrated Applications

Authelia provides SSO authentication for the following applications:

- [dokuwiki](../machines/houston/modules/dokuwiki.nix) - Wiki platform
- [linkding](../machines/houston/modules/linkding.nix) - Bookmark manager
- [miniflux](../machines/houston/modules/miniflux.nix) - RSS reader

### Integration Documentation

For a complete list of supported integrations, see:
[Authelia Integration List](https://www.authelia.com/integration/openid-connect/)

## Gmail Configuration

Authelia uses Gmail SMTP for sending notification emails (password reset, 2FA
codes, etc.).

### Generate Gmail Application Password

1. Go to: https://myaccount.google.com/apppasswords
2. Create a new application password with the name: `homelab-authelia`
3. Save the generated password

### Configure in NixOS

The Gmail application password is stored using Clan's secret management:

```bash
# Store the Gmail application password
clan vars set houston gmail-application-password/token

# Verify it's stored
clan vars get houston gmail-application-password/token
```

## Operations

### Get OpenID for Username

To retrieve the OpenID Connect identifier for a user:

```bash
# On houston server
USERNAME="<USERNAME>"
nix run nixpkgs#sqlite -- /var/lib/authelia-main/db.sqlite3 \
  "select * from user_opaque_identifier where username='$USERNAME'"
```

This is useful when troubleshooting OIDC integrations.

### Debug Configuration

To validate and debug the Authelia configuration:

```bash
# Get current config file path
systemctl cat authelia-main | grep config

# Test configuration with template expansion
nix run nixpkgs#authelia -- config template \
  --config.experimental.filters=template \
  --config /path/to/config.yml
```

## Troubleshooting

### Miniflux - Fix "This user already exists"

If you encounter the error "This user already exists" when logging into Miniflux
via OIDC, it means the OpenID Connect ID is not properly linked in the database.

**Solution:**

1. Get the user's OpenID (see
   [Get OpenID for Username](#get-openid-for-username))

2. Update the Miniflux database:

```bash
# On houston server
EMAIL="<EMAIL>"
OPENID="<OPENID>"  # from previous step

sudo -u postgres bash
psql miniflux -c "update users set openid_connect_id='$OPENID' where username='$EMAIL'"
```

### Reset Secrets

If you need to regenerate secrets (this will invalidate existing sessions):

```bash
# On houston server
clan vars generate houston authelia
systemctl restart authelia-main
```

**Warning**: Regenerating secrets will:

- Invalidate all user sessions
- Require users to log in again
- Regenerate JWT tokens and encryption keys

## Learn More

- [Official Documentation](https://www.authelia.com/overview/prologue/introduction/)
- [Integration List](https://www.authelia.com/integration/openid-connect/)
- [NixOS Module](../machines/houston/modules/authelia.nix)
