# SOPS

## Copy private age on host

- gpg
- yubikey requirement

```bash
mkdir -p ~/.config/sops/age
pass show home/bruno/homelab/age/privatekey > ~/.config/sops/age/keys.txt
```
