# LLDAP - Lightweight LDAP Directory

## What is LLDAP?

[LLDAP](https://github.com/lldap/lldap) (Light LDAP) is a lightweight
authentication server that provides a simple LDAP interface for authentication,
perfect for small infrastructures and homelabs.

Unlike full-featured LDAP servers like OpenLDAP or Active Directory, LLDAP
focuses on simplicity and ease of use while providing the essential features
needed for user authentication and management in a homelab environment.

## Why Use LLDAP?

> Lightweight LDAP made simple for homelabs

**Key benefits:**

- **Simple Setup**: Easy to deploy and configure, unlike complex LDAP servers
- **Web-Based UI**: Intuitive web interface for user and group management
- **Lightweight**: Minimal resource usage, perfect for small servers
- **LDAP Compatible**: Standard LDAP protocol for integration with other
  services
- **No Command-Line Required**: Manage users through the web UI instead of CLI
  tools
- **Homelab Focused**: Designed specifically for self-hosted infrastructure
- **Container Ready**: Runs easily in Docker/Podman with minimal configuration

## Key Features

### 1. Web-Based Administration

Modern, user-friendly web interface for managing users and groups without
touching the command line.

### 2. Standard LDAP Protocol

Fully compatible with LDAP-based authentication, integrating seamlessly with
services like Authelia, Nextcloud, and more.

### 3. User & Group Management

Simple user and group management with:

- User creation and deletion
- Group assignment
- Password management
- User attributes

### 4. Lightweight & Fast

Minimal resource footprint:

- Low memory usage
- Fast authentication responses
- Efficient database backend (SQLite)

### 5. Built for Homelabs

Designed specifically for small-scale deployments:

- No enterprise complexity
- Sensible defaults
- Quick setup

### 6. Container-Native

Easy deployment with Docker/Podman, perfect for modern infrastructure-as-code
setups.

### 7. Integration Ready

Works out-of-the-box with popular authentication systems like Authelia for SSO.

## Service Information

|                key | value                                                                           |
| -----------------: | ------------------------------------------------------------------------------- |
|  installation type | **podman**                                                                      |
| service management | `systemctl <COMMAND> podman-lldap`                                              |
|          ldap port | 3890                                                                            |
|        web ui port | 17170                                                                           |
|   forwarding ports | `ssh -L 3890:localhost:3890 -L 17170:localhost:17170 root@houston.ma-cabane.eu` |
|      admin account | **admin**                                                                       |
|     admin password | `clan vars get houston lldap/password`                                          |
| application folder | `/data/podman/lldap`                                                            |
|      backup folder | `/var/backup/lldap`                                                             |
|             backup | see [borgbackup](./borgbackup.md)                                               |

### Configuration

The LLDAP instance is configured in
[machines/houston/modules/lldap.nix](../machines/houston/modules/lldap.nix).

Key configuration parameters:

- **Base DN**: `dc=homelab,dc=lan`
- **LDAP Port**: `3890`
- **Web Interface Port**: `17170`
- **Container Image**: `lldap/lldap:2025-09-28-alpine`

## LLDAP management

### Web Interface

Access the web interface at: `http://houston:17170`

If accessing from outside the houston server, use SSH port forwarding:

```bash
ssh -L 17170:localhost:17170 root@houston.ma-cabane.eu
# Then open http://localhost:17170 in your browser
```

Login credentials:

- Username: `admin`
- Password: `clan vars get houston lldap/password`

### Users & Groups

#### List All Users

```bash
# Enable port forwarding if accessing remotely
ssh -L 3890:localhost:3890 root@houston.ma-cabane.eu

# Get users list
nix shell nixpkgs#openldap -c ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=homelab,dc=lan" \
  -w $(clan vars get houston lldap/password) \
  -b "ou=people,dc=homelab,dc=lan"
```

#### List All Groups

```bash
# Enable port forwarding if accessing remotely
ssh -L 3890:localhost:3890 root@houston.ma-cabane.eu

# Get groups list
nix shell nixpkgs#openldap -c ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=homelab,dc=lan" \
  -w $(clan vars get houston lldap/password) \
  -b "ou=groups,dc=homelab,dc=lan"
```

#### Reset Admin Password

If you lose the admin password, regenerate credentials:

```bash
# On houston server
clan vars generate houston lldap
systemctl restart podman-lldap

# Get new password
clan vars get houston lldap/password
```

## Integration with Authelia

LLDAP is used as the authentication backend for Authelia. The integration is
configured in
[machines/houston/modules/authelia.nix](../machines/houston/modules/authelia.nix).

Authelia connects to LLDAP using:

- **URL**: `ldap://127.0.0.1:3890`
- **Base DN**: `dc=homelab,dc=lan`
- **User DN**: `ou=people,dc=homelab,dc=lan`
- **Groups DN**: `ou=groups,dc=homelab,dc=lan`
- **Admin User**: `admin`

## LDAP Architecture

### Understanding LDAP Structure

LDAP (Lightweight Directory Access Protocol) organizes data hierarchically, like
an inverted tree. Each entry is identified by a unique **Distinguished Name
(DN)**, composed of attributes separated by commas.

### Main LDAP Attributes

| Attribute | Full Name           | Description                               | Example                  |
| --------- | ------------------- | ----------------------------------------- | ------------------------ |
| **dc**    | Domain Component    | Represents a component of the domain name | `dc=homelab`, `dc=lan`   |
| **ou**    | Organizational Unit | Organizational unit to group entries      | `ou=people`, `ou=groups` |
| **cn**    | Common Name         | Common name of an object (group, service) | `cn=admins`              |
| **uid**   | User ID             | Unique identifier of a user               | `uid=john`               |

### DN Reading Order

DNs are read **from right to left** (from general to specific):

```
uid=john,ou=people,dc=homelab,dc=lan
│        │         │          └─ Root domain (.lan)
│        │         └─ Subdomain (homelab)
│        └─ Organizational unit (people)
└─ User (john)
```

### Data Structure

#### Base DN

```
dc=homelab,dc=lan                    # Directory root
├── ou=people                        # Organizational unit for users
│   ├── uid=admin                    # Administrator user
│   └── uid=john                     # Standard user
└── ou=groups                        # Organizational unit for groups
    ├── cn=admins                    # Administrators group
    └── cn=users                     # Users group
```

#### Example User DN

```
uid=username,ou=people,dc=homelab,dc=lan
```

This DN means:

- A user identified by `username`
- In the organizational unit `people`
- Of the domain `homelab.lan`

#### Example Group DN

```
cn=groupname,ou=groups,dc=homelab,dc=lan
```

This DN means:

- A group named `groupname`
- In the organizational unit `groups`
- Of the domain `homelab.lan`

## Learn More

- [GitHub Repository](https://github.com/lldap/lldap)
- [Authelia Integration Guide](https://www.authelia.com/integration/ldap/introduction/)
- [NixOS Module](../machines/houston/modules/lldap.nix)
