# cab1e

This server acts as a VPN server hosted on an Infomaniak server.

To install a NixOS instance on Infomaniak's public cloud, you need to use
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

`nixos-anywhere` allows you to install NixOS on an existing system.

## Configuration

### Generating WireGuard Private/Public Keys

#### Creating the Server Key

```bash
wg genkey | tee ./hosts/cab1e/wireguard.priv | wg pubkey > ./hosts/cab1e/wireguard.pub
```

Then, store the WireGuard private key in the SOPS secrets file:

```yaml
services:
  wireguard:
    private_peer: <./hosts/cab1e/wireguard.priv> content
```

#### Creating Client Keys

Repeat the operation for each client:

```bash
wg genkey | tee ./hosts/<HOSTNAME>/wireguard.priv | wg pubkey > ./hosts/<HOSTNAME>/wireguard.pub
```

Then, store the WireGuard private key in the corresponding SOPS secrets file:

```yaml
services:
  wireguard:
    private_peer: <./hosts/<HOSTNAME>/wireguard.priv> content
```

### Host Configuration

First, follow the general documentation on [preparing a host](/hosts/README.md).

## Instance Creation

Infomaniak's public cloud is based on OpenStack. We will first install an Ubuntu
instance:

```bash
pass show nix-homelab/external-services/infomaniak/PCU-PALZHK9/openstackRC > ./hosts/cab1e/PCU-PALZHK9.openstackrc
source ./hosts/cab1e/PCU-PALZHK9.openstackrc
openstack flavor list | grep ram4 | grep disk50
openstack image list | grep -i ubuntu

openstack keypair create nixos-net-user > ./hosts/cab1e/ssh-infomaniak-nixos-net-user.priv
chmod 600 ./hosts/cab1e/ssh-infomaniak-nixos-net-user.priv

openstack server create --image "Ubuntu 24.04 LTS Noble Numbat" \
  --flavor a2-ram4-disk50-perf1 --key-name nixos-net-user \
  --network ext-net1 cab1e

openstack security group create cab1e
openstack security group rule create --ingress \
  --protocol tcp --dst-port 22 \
  --ethertype IPv4 cab1e
openstack security group rule create --ingress \
  --protocol udp --dst-port 54321 \
  --ethertype IPv4 cab1e
openstack security group rule create --ingress \
  --protocol tcp --dst-port 53545 \
  --ethertype IPv4 cab1e
openstack security group rule create --ingress \
  --protocol udp --dst-port 53545 \
  --ethertype IPv4 cab1e

openstack server add security group cab1e cab1e
```

Once the `./hosts/cab1e/*` configuration files are ready, test the build:

```bash
just nixos-build cab1e --show-trace
```

If the build is successful, proceed with deployment:

```bash
SERVER_ADDRESS=$(openstack server show cab1e -f json | jq -r '.addresses."ext-net1"[0]')
nixos-anywhere --generate-hardware-config nixos-generate-config ./hosts/cab1e/hardware-configuration.nix --flake .#cab1e ubuntu@$SERVER_ADDRESS
# Copy the keys ./hosts/cab1e/ssh_host_xxx to the server /etc/ssh
just nixos-remote-update cab1e $SERVER_ADDRESS
```

The machine is now ready. You can connect via SSH or VNC:

```bash
ssh -i ./hosts/cab1e/ssh-infomaniak-nixos-net-user.priv ubuntu@$SERVER_ADDRESS
openstack console url show cab1e
```
