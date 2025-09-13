# houston

Houston is the center of public control. It provides the authentication service

### Instance type

- Provider: hetzner
- Instance type: [CX32](https://www.hetzner.com/cloud/)
- CPU: 4 Intel vCPU cores
- RAM: 8 GB
- Storage: 80 GB SSD
- Included trafic: 20TB

### Services

- authentification ([authelia](../../docs/authelia.md)
- Web server (nginx)
  - miniflux (Minimalist and Opinionated Feed Reader)
  - linkding (self-hosted bookmark manager designed to be minimal and fast)
- Zerotier controller

## Initial deployment

1. Add new machine

```bash
just machine-add houston
```

2. Get Device ID and edit `machines/houston/configuration.nix` and change host
   IP and installation disk destination `disko.devices.disk.main.device` (ex:
   `/dev/disk/by-id/xxx` or `/dev/sda`)

```bash
just machine-get-disk-id 192.168.254.137
```

### Terraform

```bash
nix run .#terraform
```

## Update deployment

Update host installation

```bash
clan machines update houston
```

### Redeploy

```bash
nix run .#terraform
nix run .#terraform.terraform -- apply -replace "hcloud_server.houston"
```

### Destroy

```bash
nix run .#terraform
nix run .#terraform.terraform -- destroy -target "hcloud_server.houston"
```

## Update deployment

```bash
clan machines update houston
```

## Links

- [hetzner](../hetzner.md)(internal)
