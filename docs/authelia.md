# Authelia

Authelia is an open-source authentication and authorization server providing
2-factor authentication and single sign-on (SSO) for applications via a web
portal.

## Gmail Application Password

To generate an application password, go to:
https://myaccount.google.com/apppasswords

Use the name: `homelab-authelia`

## Integration

[Integration list](https://www.authelia.com/integration/openid-connect/)

- [miniflux](../machines/houston/modules/miniflux.nix)
- [linkding](../machines/houston/modules/linkding.nix)

## Tips

### Get OpenID for Username

On `houston` server:

```bash
USERNAME="<USERNAME>"
nix run nixpkgs#sqlite -- /var/lib/authelia-main/db.sqlite3 "select * from user_opaque_identifier where username='$USERNAME'"
```

### Miniflux

#### Fix "This user already exists"

On `houston` server:

```bash
EMAIL="<EMAIL>"
OPENID="<OPENID>"
sudo -u postgres bash 
psql miniflux -c "update users set openid_connect_id='$OPENID' where username='$EMAIL'"
```

## Configuration

The configuration file for Authelia can be found in the system configuration.

### Debug

```bash
nix run nixpkgs#authelia -- config template --config.experimental.filters=template --config /nix/store/d8gv89l9p534i6175a4849d53vz3qhwi-config.yml
```

## User Management

### Create New User

```bash
authelia-create-user <username> <email> <displayname>
```
