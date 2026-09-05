<!-- BEGIN SECTION feature_informations file=./.templates/feature_zitadel.html -->

<div class="feature-detail">
  <h1 id="zitadel">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/zitadel.png" width="64" height="64" alt="ZITADEL" style="vertical-align: middle; margin-right: 10px;"/>
    ZITADEL
  </h1>
  <h2>Basic Information</h2>
  <p>Identity and access management platform</p>
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
        <td>2.71.7</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://github.com/zitadel/zitadel">https://github.com/zitadel/zitadel</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/zitadel">modules/features/zitadel</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is ZITADEL?

[ZITADEL](https://zitadel.com/) is an open-source Identity Provider (IdP)
focused on security, scalability, and modern authentication standards. It
provides Single Sign-On (SSO), OAuth2/OIDC, and SAML authentication for
self-hosted applications.

ZITADEL serves as the central authentication gateway for all homelab services,
enabling unified user management and secure access control.

---

## Why Use ZITADEL?

> Secure, modern identity management with strong defaults

**Key benefits:**

- **Single Sign-On**: One login for all applications
- **Modern Protocols**: OAuth2/OIDC, SAML support
- **Security First**: Built-in MFA, WebAuthn, passkeys
- **Multi-Tenant**: Organizations and projects separation
- **User Management**: Centralized identity management
- **API-Driven**: Everything configurable via API

---

## Login

Administration account

```bash
sudo -u postgres psql zitadel -c "SELECT email, password_change_required, password_changed FROM projections.users14_humans;"
clan vars get MACHINE zitadel/steps-secrets
```

---

## Configuration

### Default settings

**Login behavior and security**

- `Force MFA for all users`
- Disable `User Registration allowed`

#### SMTP setting

Create application password => https://myaccount.google.com/apppasswords

**SMTP Provider Settings**

- host: `smtp.gmail.com:587`
- use_tls: `yes`
- username: `config.homelab.stmpAccountUsername`
- password: `clan vars get MACHINE gmail-apps-zitadel-password/token`

**Sender settings**

- email address: `config.homelab.stmpAccountUsername`
- sender name: `ma-cabane account notification`

**Do not forget to activate the SMTP provider**

### Configuration organization

**Login behavior and security**

- `Force MFA for all users`
- Disable `User Registration allowed`

### Create project

To assign fine-grained permissions to an application and authorize
authentication through ZITADEL, create one project per application. This allows
roles to be attached to each application independently.

Create `APPLICATIONNAME`

- disable `Assert Roles on Authentication`
- enable `Check authorization on Authentication`
- disable `Check for Project on Authentication`

For each project, add the roles:

- admin
- user

### Add authorization

On the project

- select users
- select roles

### Supported applications

The following feature applications are compatible with ZITADEL through
OAuth2/OIDC. When a feature document exists, the application name links to it.

| Application | Protocol | Documentation | Status |
| ----------- | -------- | ------------- | ------ |
| [Miniflux](./miniflux.md) | OIDC | ZITADEL example below and [Miniflux feature](./miniflux.md) | Configured with ZITADEL |
| [Linkding](./linkding.md) | OIDC | ZITADEL example below and [Linkding feature](./linkding.md) | Configured with ZITADEL |
| [NetBird](./netbird.md) | OIDC | [NetBird feature](./netbird.md) | Native ZITADEL setup documented |
| [DokuWiki](./dokuwiki.md) | OAuth2/OIDC generic plugin | [DokuWiki feature](./dokuwiki.md) | Compatible through generic OAuth |

### Example with Miniflux

**Website information**

- appDomain: `journaliste.ma-cabane.eu`

#### ZITADEL config

1. Create application:
   - Type `WEB`
   - Authentication `PKCE`
   - Redirect URIs:
     - `https://journaliste.ma-cabane.eu/oauth2/oidc/callback`
     - `https://journaliste.ma-cabane.eu/oauth2/oidc/redirect`
   - Post Logout URIs:
     - `https://journaliste.ma-cabane.eu`
2. Copy:
   - Client ID

#### Miniflux config

```env
OAUTH2_PROVIDER=oidc
OAUTH2_CLIENT_ID=<client-id>
OAUTH2_REDIRECT_URL=https://journaliste.ma-cabane.eu/oauth2/oidc/callback
OAUTH2_OIDC_DISCOVERY_ENDPOINT=https://douane.ma-cabane.eu
OAUTH2_USER_CREATION=1
```

### Example with linkding

**Website information**

- appDomain: `bonnes-addresses.ma-cabane.eu`

#### ZITADEL config

1. Create application:
   - Type `WEB`
   - Authentication `PKCE`
   - Redirect URIs:
     - `https://bonnes-adresses.ma-cabane.eu/oidc/callback`
   - Post Logout URIs:
     - `https://bonne-addresses.ma-cabane.eu`
2. Copy:
   - Client ID

#### Linkding config

```env
LD_ENABLE_OIDC = "true";

OIDC_RP_CLIENT_ID=<client_id>
OIDC_RP_CLIENT_SECRET=<client_secret>

OIDC_OP_AUTHORIZATION_ENDPOINT=https://<zitadel>/oidc/v1/authorize
OIDC_OP_TOKEN_ENDPOINT=https://<zitadel>/oidc/v1/token
OIDC_OP_USER_ENDPOINT=https://<zitadel>/oidc/v1/userinfo

OIDC_RP_SIGN_ALGO=RS256
OIDC_RP_SCOPES=openid email profile
```

### Example with grafana

**Website information**

- appDomain: `lampiotes.ma-cabane.eu`

#### ZITADEL config

**SOURCE:** https://schoenwald.aero/posts/2025-02-12_integrating_zitadel_as_an_oidc_provider_in_grafana/

1. Create application:
   - Type `WEB`
   - Authentication `PKCE`
   - Redirect URIs:
     - `https://lampiotes.ma-cabane.eu/login/generic_oauth`
   - Post Logout URIs:
     - `https://lampiotes.ma-cabane.eu/login`
2. Copy:
   - Client ID
3. Create the `groupsClaim` action script

   ```javascript
   function groupsClaim(ctx, api) {
     if (ctx.v1.user.grants === undefined || ctx.v1.user.grants.count == 0) {
       return;
     }

     let grants = [];
     ctx.v1.user.grants.grants.forEach((claim) => {
       claim.roles.forEach((role) => {
         grants.push(role);
       });
     });

     api.v1.claims.setClaim("groups", grants);
   }
   ```

4. Enable script on `Complement token` flow
   - Enable for `Pre access token creation`
   - Enable for `Pre Userinfo creation`

#### Grafana config

```nix
      "auth.anonymous" = {
        enabled = true;
        org_name = "ma cabane";
        org_role = "Viewer";
        hide_version = true;
      };

      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        auto_login = false;
        name = "Zitadel";
        icon = "signin";
        client_id = "371357670822707201";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];

        auth_url = "https://douane.ma-cabane.eu/oauth/v2/authorize";
        token_url = "https://douane.ma-cabane.eu/oauth/v2/token";
        api_url = "https://douane.ma-cabane.eu/oidc/v1/userinfo";

        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        email_attribute_path = "email";
        allow_assign_grafana_admin = true;

        use_pkce = true;
        groups_attribute_path = "groups";
        role_attribute_strict = true;
        role_attribute_path = builtins.concatStringsSep " || " [
          "contains(groups, 'grafana-superadmins') && 'GrafanaAdmin'"
          "contains(groups, 'grafana-admins') && 'Admin'"
          "contains(groups, 'grafana-editors') && 'Editor'"
          "contains(groups, 'grafana-viewers') && 'Viewer'"
        ];
      };
```

## Operations

### Reset Admin (bootstrap)

ZITADEL does not allow re-running bootstrap.

To recreate admin:

On `<Machine>`

```bash
sudo systemctl stop zitadel
sudo -u postgres dropdb zitadel
sudo -u postgres psql  -c "\\l"
```

On clan admin desktop

```bash
rm -rf vars/per-machine/MACHINE/zitadel
clan machines update MACHINE
```

---

### Health Check

```
http://127.0.0.1:<port>/debug/healthz
```

---

## Known Limitations

- Bootstrap (`FirstInstance`) is **one-shot**
- Config merge (`steps`) can be tricky
- No full runtime config dump

---

## Learn More

- [https://zitadel.com/docs/](https://zitadel.com/docs/)
- [https://github.com/zitadel/zitadel](https://github.com/zitadel/zitadel)
- [https://zitadel.com/docs/guides/integrate/login/oidc](https://zitadel.com/docs/guides/integrate/login/oidc)
