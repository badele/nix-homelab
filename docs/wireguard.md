# Wireguard

Wireguard is an alterntative to OpenVPN and IPSec alternative, it's most performant and most secure that previous two product.

## Mikrotik router configuration

This router accept wireguard client and route all trafics to internal homelab network

```
/interface wireguard
add listen-port=13231 mtu=1420 name=wireguard1 public-key="3TjlMI639ikErw1BNkPTex50N382zieu/01eYhAJoic="
/interface wireguard peers
add allowed-address=10.123.21.1/32 comment="Bruno's phone" endpoint-port=13231 interface=wireguard1 public-key="4fpdvNzfxkpem3kU3+fPU8ezdbXC59nbpWoDjLnsAmw="
/ip address
add address=10.123.21.254/24 interface=wireguard1 network=10.123.21.0
/ip firewall filter
add action=accept chain=input comment="Allow wireguard listener" dst-port=13231 protocol=udp
```

## Android

Use Wireguard application developed by WireGuard Development Team

### Interface
```
Name: home
public-key: 4fpdvNzfxkpem3kU3+fPU8ezdbXC59nbpWoDjLnsAmw=
Address: 10.123.21.1/32
Listener port: 13213
```

### Peers
```
public-key: 3TjlMI639ikErw1BNkPTex50N382zieu/01eYhAJoic=
keep connexion: 25
endpoint: xxx.xxx.xxx.xxx:13231
Allowed address: 10.123.21.0/24, 192.168.254.254/24, 192.168.0.0/24
```