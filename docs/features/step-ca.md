<!-- BEGIN SECTION feature_informations file=./.templates/feature_step-ca.html -->

<div class="feature-detail">
  <h1 id="step-ca">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/step-ca.png" width="64" height="64" alt="Step CA" style="vertical-align: middle; margin-right: 10px;"/>
    Step CA
  </h1>
  <h2>Basic Information</h2>
  <p>Private certificate authority (X.509 & SSH) & ACME server for secure automated certificate management, so you can use TLS everywhere & SSO for SSH</p>
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
        <td>0.28.4</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://smallstep.com/certificates/">https://smallstep.com/certificates/</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/step-ca">modules/features/step-ca</a></td>
      </tr>
    </tbody>
  </table>
  <h2>⚠️ Deprecation Notice</h2>
  <div class="deprecation-notice">
    <p><em>This feature is deprecated. While it works fine, it has significant limitations:
it's difficult to add the self-signed CA to all devices. For example, Firefox
on Android doesn't use the Android root CA store.

Recommended alternative: Use public domain names (with private IPs) and DNS-01
challenge for automated certificate management with Let's Encrypt.
</em></p>
  </div>
</div>

<!-- END SECTION feature_informations -->

## What is Step CA?

[Step CA](https://smallstep.com/certificates/) is an online certificate
authority and related tools for secure automated certificate management. It
allows you to run your own private Certificate Authority (CA) to issue X.509 and
SSH certificates for your internal infrastructure.

Step CA provides a modern, developer-friendly alternative to traditional CAs,
with ACME protocol support for automated certificate issuance and renewal,
similar to Let's Encrypt but for your private network.

## Why Was Step CA Used?

> Private certificate authority for internal services with automated certificate
> management

**Original benefits:**

- **Private CA**: Issue certificates for internal-only services
- **ACME Support**: Automated certificate generation and renewal
- **No External Dependencies**: Works completely offline
- **SSH Certificates**: Support for SSH certificate authentication
- **Fine-grained Control**: Complete control over certificate policies
- **No Rate Limits**: Unlike public CAs, no issuance limits

## Key Features

### 1. ACME Protocol Support

Full ACME protocol implementation for automated certificate management:

```nix
security.acme = {
  acceptTerms = true;
  defaults.server = "https://ca.ma-cabane.net:10000/acme/acme/directory";
  defaults.email = "admin@ma-cabane.eu";
};
```

### 2. Automatic Certificate Generation

Certificates and keys were automatically generated using `step-cli`:

- Root CA password and keypair
- Intermediate CA password and keypair
- Automatic signing of intermediate by root

## Misc

### System-wide CA Trust

The root CA was automatically trusted system-wide:

```nix
security.pki.certificateFiles = [
  secrets.step-ca-root-ca.files."root-ca.crt".path
];
```

### Reset All ACME Certificates

For reseting all CA, you can use the `@service-step-ca-reset-all-acme-certs`
command

## Learn More

- [Step CA Official Documentation](https://smallstep.com/docs/step-ca/)
- [Step CLI Documentation](https://smallstep.com/docs/step-cli/)
- [ACME Protocol](https://letsencrypt.org/docs/acme-protocol-updates/)
- [Recommended Alternative: ACME with DNS-01](./acme.md)
