# Certificate

## Let's Encrypt

Use the let's encrypt and gandi DNS-01 challenge. See `nixos/roles/acme.nix`

for using the wildcard domain in nginx configuration, add this below block

```
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;
```

