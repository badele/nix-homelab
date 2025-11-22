<!-- BEGIN SECTION feature_informations file=./.templates/feature_lldap.html -->

<div class="feature-detail">
  <h1 id="lldap">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lldap.png" width="64" height="64" alt="LLDAP" style="vertical-align: middle; margin-right: 10px;"/>
    LLDAP
  </h1>
  <h2>Basic Information</h2>
  <p>Lightweight authentication server that provides an opinionated, simplified LDAP interface for authentication</p>
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
        <th>Version</th>
        <td>0.6.2</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://github.com/lldap/lldap">https://github.com/lldap/lldap</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/lldap">modules/features/lldap</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is LLDAP?

[LLDAP](https://github.com/lldap/lldap) is a lightweight LDAP authentication
server designed for small infrastructures and homelabs. It provides a simple
LDAP interface with a web-based UI for user and group management.

Unlike complex LDAP servers like OpenLDAP or Active Directory, LLDAP focuses on
simplicity while providing essential authentication features needed for homelab
environments.

![LLDAP interface](../imgs/lldap.png)

## Why Use LLDAP?

> Lightweight LDAP made simple for homelabs

**Key benefits:**

- **Simple Setup**: Easy to deploy and configure, unlike complex LDAP servers
- **Web-Based UI**: Intuitive interface for user and group management
- **Lightweight**: Minimal resource usage with SQLite backend
- **LDAP Compatible**: Standard LDAP protocol for integration with services
- **Homelab Focused**: Designed for self-hosted infrastructure
- **Container Ready**: Easy deployment with Docker/Podman
- **Authelia Integration**: Works seamlessly with SSO systems

## Configuration

**Key parameters:**

- **Base DN**: `dc=homelab,dc=lan`
- **LDAP Port**: `3890`
- **Web Interface**: Port `17170`
- **Admin User**: `admin`
- **Admin Password**: `clan vars get houston lldap/password`

**Access web interface:**

```bash
# Remote access via SSH port forwarding
ssh -L 17170:localhost:17170 root@houston.ma-cabane.eu
# Then open http://localhost:17170
```

## Operations

### List Users

```bash
ssh -L 3890:localhost:3890 root@houston.ma-cabane.eu

nix shell nixpkgs#openldap -c ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=homelab,dc=lan" \
  -w $(clan vars get houston lldap/password) \
  -b "ou=people,dc=homelab,dc=lan"
```

### List Groups

```bash
nix shell nixpkgs#openldap -c ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=homelab,dc=lan" \
  -w $(clan vars get houston lldap/password) \
  -b "ou=groups,dc=homelab,dc=lan"
```

## LDAP Structure

LDAP organizes data hierarchically with Distinguished Names (DN):

**Base structure:**

```
dc=homelab,dc=lan ├── ou=people │ ├── uid=admin │ └── uid=username └── ou=groups
├── cn=admins └── cn=users
```

**Example DNs:**

- User: `uid=username,ou=people,dc=homelab,dc=lan`
- Group: `cn=groupname,ou=groups,dc=homelab,dc=lan`

## Learn More

- [GitHub Repository](https://github.com/lldap/lldap)
- [Authelia Integration Guide](https://www.authelia.com/integration/ldap/introduction/)
