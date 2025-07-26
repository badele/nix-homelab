# Hetzner

Hetzner Cloud is a German cloud hosting provider that offers virtual private
servers (VPS) and dedicated servers. It's known for providing high-performance
infrastructure at competitive prices with excellent price-to-performance ratios.

## Service used

- **Storage Box:** Secure online storage service with FTP/SFTP access, ideal for
  backups and data archiving (with borgbackup).
- **Cloud Computer:** High-performance virtual private servers (VPS) with
  flexible configuration and hourly billing.

## Token creation

To create a token, you need to connect to the Hetzner console, in the
`security -> API tokens` section

Store to clan secrets

```bash
clan secrets set hetzner-homelab-token
```

## Terraform

There is a
[Terraform provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
to manage Hetzner services
