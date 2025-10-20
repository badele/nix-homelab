# ACME - Automatic Certificate Management

## What is ACME?

[ACME](https://letsencrypt.org/docs/client-options/) (Automatic Certificate
Management Environment) is a protocol for automating the process of certificate
issuance and renewal. This homelab uses ACME with
[Let's Encrypt](https://letsencrypt.org/) to automatically obtain and manage
SSL/TLS certificates for all services.

ACME eliminates the manual work of creating, validating, installing, and
renewing certificates, providing secure HTTPS connections for all your
self-hosted applications.

## Why Use ACME?

> Automated, free SSL/TLS certificates for secure HTTPS everywhere

**Key benefits:**

- **Fully Automated**: Certificate generation and renewal happen automatically
- **Free Certificates**: Let's Encrypt provides trusted certificates at no cost
- **Always Valid**: Auto-renewal ensures certificates never expire
- **Browser Trusted**: Certificates are trusted by all major browsers
- **Easy Integration**: NixOS ACME module handles everything automatically
- **Multiple Challenge Types**: Support for HTTP-01 and DNS-01 validation

## Key Features

### 1. Automatic Certificate Generation

ACME automatically requests and obtains SSL/TLS certificates from Let's Encrypt
when you deploy a new service.

### 2. Automatic Renewal

Certificates are automatically renewed every 60 days (Let's Encrypt certificates
are valid for 90 days), ensuring you never have expired certificates.

### 3. HTTP-01 and DNS-01 Challenges

Support for multiple validation methods:

- **HTTP-01**: Validation via HTTP (most common, requires port 80)
- **DNS-01**: Validation via DNS records (supports wildcard certificates)

### 4. Nginx Integration

Seamless integration with Nginx for automatic HTTPS configuration and challenge
serving.

### 5. Free Certificates

All certificates are provided by Let's Encrypt at no cost, trusted by all major
browsers.

## Configuration

### Global ACME Settings

Global ACME configuration is defined in
[modules/system/acme.nix](../modules/system/acme.nix):

```nix
security.acme.acceptTerms = true;
security.acme.defaults.email = "admin@ma-cabane.eu";
```

This configuration:

- Accepts Let's Encrypt Terms of Service
- Sets the admin email for certificate notifications

### Per-Service Configuration

Each service can request its own certificate by enabling ACME in its Nginx
virtual host configuration.

## Challenge Types

ACME supports different challenge types to verify domain ownership.

### HTTP-01 Challenge

The HTTP-01 challenge is the most common method. Let's Encrypt verifies domain
ownership by requesting a specific file via HTTP.

**Requirements:**

- Port 80 must be accessible from the internet
- Nginx serves the ACME challenge files automatically

**Usage in NixOS:**

```nix
services.nginx.virtualHosts."encyclopedie.ma-cabane.eu" = {
  forceSSL = true;
  enableACME = true;  # Automatically uses HTTP-01 challenge

  locations."/" = {
    proxyPass = "http://127.0.0.1:10011";
  };
};
```

**How it works:**

1. Nginx requests a certificate from Let's Encrypt
2. Let's Encrypt responds with a challenge token
3. Nginx serves the token at
   `http://encyclopedie.ma-cabane.eu/.well-known/acme-challenge/<token>`
4. Let's Encrypt verifies the token
5. Certificate is issued

### DNS-01 Challenge (Wildcard)

currently not used in this homelab

## Operations

### List All Certificates

```bash
# List all ACME certificates
ls -la /var/lib/acme/

# Check certificate details
ls -la /var/lib/acme/encyclopedie.ma-cabane.eu/
```

Each directory contains:

- `cert.pem` - Certificate
- `chain.pem` - Certificate chain
- `fullchain.pem` - Full certificate chain
- `key.pem` - Private key

### Renew Certificates Manually

Certificates are automatically renewed by systemd timers. To manually trigger
renewal:

```bash
# Renew all certificates
systemctl start acme-*.service

# Renew specific certificate
systemctl start acme-encyclopedie.ma-cabane.eu.service
```

### Check Certificate Expiration

```bash
# Check certificate expiration for a specific domain
openssl x509 -in /var/lib/acme/encyclopedie.ma-cabane.eu/cert.pem -noout -enddate

# Check from remote (via HTTPS)
echo | openssl s_client -servername encyclopedie.ma-cabane.eu \
  -connect encyclopedie.ma-cabane.eu:443 2>/dev/null | \
  openssl x509 -noout -dates
```

### List Renewal Timers

```bash
# List all ACME renewal timers
systemctl list-timers | grep acme
```

## Troubleshooting

### Force Certificate Regeneration

If you need to regenerate a certificate:

```bash
# Stop and disable the service temporarily
systemctl stop acme-encyclopedie.ma-cabane.eu.service

# Remove existing certificate
rm -rf /var/lib/acme/encyclopedie.ma-cabane.eu

# Rebuild NixOS configuration to regenerate
nixos-rebuild switch

# Or manually start the service
systemctl start acme-encyclopedie.ma-cabane.eu.service
```

### Rate Limiting

Let's Encrypt has rate limits. If you hit the limit:

- **Failed validation limit:** 5 failures per account, per hostname, per hour
- **Certificates per registered domain:** 50 per week
- **Duplicate certificate limit:** 5 per week

To avoid rate limiting during testing, use Let's Encrypt's staging environment:

```nix
security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
```

**Important:** Staging certificates are not trusted by browsers. Only use for
testing!

## Learn More

- [Let's Encrypt Official Site](https://letsencrypt.org/)
- [ACME Protocol Documentation](https://letsencrypt.org/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [NixOS ACME Module Documentation](https://nixos.org/manual/nixos/stable/index.html#module-security-acme)
- [NixOS Configuration](../modules/system/acme.nix)
