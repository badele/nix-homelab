# Terraform

Terraform is an infrastructure as code (IaC) tool developed by HashiCorp that
allows you to define, provision and manage cloud infrastructure in a declarative
way. It uses configuration files to describe the required resources and
maintains a state of the deployed infrastructure.

## Services used

- **OpenTofu:** Open-source fork of Terraform used as execution engine for a
  completely free and open-source approach.
- **Terranix:** Nix integration for Terraform allowing to write the
  configuration in Nix instead of HCL, thus offering better integration with the
  Nix ecosystem.

## Backend encryption

The Terraform state file is automatically encrypted to protect sensitive
infrastructure data:

- **Encryption method:** AES-GCM with mandatory enforcement
- **Key derivation:** PBKDF2 with passphrase stored in clan secrets
- **Required secret:** `tf-encryption-passphrase` managed by clan

The encryption configuration is automatically applied via the `TF_ENCRYPTION`
environment variable during execution.

## Useful commands

### Encryption passphrase generation

Used for encrypt the localy terraform state

```bash
pwgen 32 -s
clan secrets set tf-encryption-passphrase
```

To execute Terraform in this project:

```bash
# Execute Terraform via Nix
nix run .#terraform

# Encryption secrets are automatically retrieved
# clan secrets get tf-encryption-passphrase
```

## Providers

### Hetzner

Get API token from [hetzner account](./hetzner.md)
