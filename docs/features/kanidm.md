<!-- BEGIN SECTION feature_informations file=./.templates/feature_kanidm.html -->

<div class="feature-detail">
  <h1 id="kanidm">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kanidm.png" width="64" height="64" alt="Kanidm" style="vertical-align: middle; margin-right: 10px;"/>
    Kanidm
  </h1>
  <h2>Basic Information</h2>
  <p>Simple, secure and fast identity management platform</p>
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
        <td>1.6.4</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://kanidm.com/">https://kanidm.com/</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/kanidm">modules/features/kanidm</a></td>
      </tr>
    </tbody>
  </table>
  <h2>⚠️ Deprecation Notice</h2>
  <div class="deprecation-notice">
    <p><em>While lightweight and performant, Kanidm requires manual configuration for some operations. Migrated to Authentik for better web UI.
</em></p>
  </div>
</div>

<!-- END SECTION feature_informations -->

## What is Kanidm?

[Kanidm](https://kanidm.com/) is a simple, secure and fast identity management
platform written in Rust. It provides modern authentication and authorization
services with a focus on security, performance, and ease of use.

Kanidm offers LDAP compatibility, OAuth2/OIDC support, and WebAuthn
authentication, making it suitable for securing applications and infrastructure.

## Why Was Kanidm Used?

> Rust-based identity management with modern security features

**Key benefits:**

- **High Performance**: Written in Rust for speed and memory safety
- **Modern Auth**: WebAuthn, OAuth2, and OIDC support out of the box
- **LDAP Compatible**: Works with existing LDAP-aware applications
- **Security Focused**: Built-in protection against common attacks
- **Low Resource Usage**: Efficient resource consumption
- **CLI Management**: Powerful command-line interface for administration
- **Automated Backups**: Built-in online backup functionality

## Learn More

- [Kanidm Official Website](https://kanidm.com/)
- [Kanidm Documentation](https://kanidm.github.io/kanidm/stable/)
- [Kanidm GitHub Repository](https://github.com/kanidm/kanidm)
- [Alternative: Authentik](./authentik.md)
