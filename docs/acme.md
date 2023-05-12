# Certificate

## Let's Encrypt

Use the let's encrypt and gandi DNS-01 challenge. See `nixos/roles/acme.nix`

for using the wildcard domain in nginx configuration, add this below block

```
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;
```

# Private services

The trick for private https services is to use ACME in DNS mode and then add the corresponding IP address to the /etc/hosts file on the client machine.

Therefore, you must perform a `nixos.deploy` on the client machines.

TODO: Disable local `nixos.deploy` and move it to coredns server (the coredns is allready configured)