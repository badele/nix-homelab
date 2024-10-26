# Prometheus

## Mikrotik SNMP

The mikrotik-export seem not working, i prefed use the SNMP exporter

```
/snmp community
set [ find default=yes ] addresses=192.168.254.100/32
/snmp
set enabled=yes
```
