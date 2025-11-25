<!-- BEGIN SECTION feature_informations file=./.templates/feature_tailscale.html -->

<div class="feature-detail">
  <h1 id="tailscale">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/tailscale.png" width="64" height="64" alt="Tailscale" style="vertical-align: middle; margin-right: 10px;"/>
    Tailscale
  </h1>
  <h2>Basic Information</h2>
  <p>Node agent for Tailscale, a mesh VPN built on WireGuard</p>
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
        <td>1.90.6</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://tailscale.com">https://tailscale.com</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/tailscale">modules/features/tailscale</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is Tailscale?

[Tailscale](https://tailscale.com/) is a zero-config VPN that creates a secure
network between your devices using WireGuard. It builds a mesh network where
each device can communicate directly with others, regardless of their physical
location or network topology.

Tailscale handles NAT traversal, authentication, and encryption automatically,
making it extremely easy to set up secure remote access to your homelab.

## Why Use Tailscale?

> Zero-config VPN with automatic mesh networking

**Key benefits:**

- **Zero Configuration**: Automatic NAT traversal and peer-to-peer connections
- **Secure by Default**: WireGuard encryption with modern cryptography
- **Mesh Networking**: Direct device-to-device connections without central
  server
- **Cross-Platform**: Works on Linux, Windows, macOS, iOS, Android
- **Access Control**: Fine-grained permissions via ACL policies
- **Magic DNS**: Automatic DNS resolution for all devices
- **Easy Management**: Web-based admin console for device management

## Configuration

**Auth Key Setup:**

1. Generate an auth key from the
   [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Configure options:
   - **Reusable**: Enable for multiple machines
   - **Ephemeral**: Auto-remove when device goes offline
   - **Pre-approved**: Skip manual device approval
   - **Tags**: Auto-tag devices for ACL rules

3. Deploy with the auth key:

```bash
# Auth key will be prompted during deployment
clan machine <MACHINE_NAME> update
```

## Learn More

- [Tailscale Official Website](https://tailscale.com/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale ACL Guide](https://tailscale.com/kb/1018/acls/)
