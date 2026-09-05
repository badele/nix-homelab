<!-- BEGIN SECTION feature_informations file=./.templates/feature_vector.html -->

<div class="feature-detail">
  <h1 id="vector">
    <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/vector.webp" width="64" height="64" alt="Vector" style="vertical-align: middle; margin-right: 10px;"/>
    Vector
  </h1>
  <h2>Basic Information</h2>
  <p>High-performance observability data pipeline</p>
  <table>
    <tbody>
      <tr>
        <th>Category</th>
        <td>
<a href="/docs/all-features.md#system-health">System Health</a>
        </td>
      </tr>
      <tr>
        <th>Platform</th>
        <td>nixos</td>
      </tr>
      <tr>
        <th>Version</th>
        <td>0.55.0</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://github.com/vectordotdev/vector">https://github.com/vectordotdev/vector</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/vector">modules/features/vector</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is Vector?

[Vector](https://vector.dev/) is an observability data pipeline. It receives
events, parses and enriches them, then forwards the normalized data to storage
systems.

In this homelab, Vector is the log collector in front of VictoriaLogs. It
currently receives CEF events over UDP, enriches MikroTik firewall and login
events, forwards the resulting log stream to VictoriaLogs, and exports its own
Prometheus metrics for VictoriaMetrics.

## Why Use Vector?

> A local log pipeline between network devices and VictoriaLogs

**Key benefits:**

- **CEF Ingestion**: Receives remote CEF/syslog events over UDP
- **MikroTik Enrichment**: Extracts RouterOS firewall and login details into
  structured fields
- **VictoriaLogs Sink**: Sends normalized events to the VictoriaLogs
  Elasticsearch bulk endpoint
- **Local Metrics**: Exposes Vector internal metrics on a local Prometheus
  exporter
- **Grafana Ready**: Publishes a scrape job and provisions the Vector dashboard

## Configuration

### Enable the feature

```nix
homelab.features.vector = {
  enable = true;

  cef.enable = true;
  cef.listenInterfaces = [
    "vlan-lan"
  ];

  cef.mikrotikFirewall.enable = true;
  cef.mikrotikLogin.enable = true;
  cef.mikrotikDhcp.enable = true;

  victorialogs.enable = true;
};
```

`cef.listenInterfaces` is required when CEF ingestion is enabled. The module
opens `homelab.features.vector.cef.port` on those interfaces.

### CEF input port

The default CEF UDP port is:

```nix
homelab.features.vector.cef.port = 5515;
```

Override it when devices already send logs to another port:

```nix
homelab.features.vector.cef.port = 5514;
```

### Forward to VictoriaLogs

When `homelab.features.vector.victorialogs.enable = true`, Vector writes events
to:

```text
http://127.0.0.1:10230/insert/elasticsearch/
```

The default endpoint is derived from the VictoriaLogs port registry entry. It
can be overridden explicitly:

```nix
homelab.features.vector.victorialogs.endpoint =
  "http://127.0.0.1:10230/insert/elasticsearch/";
```

The VictoriaLogs sink uses these fields:

```text
_msg_field=message
_time_field=timestamp
_stream_fields=service,source_host,app_name
```

## MikroTik Logs

Vector can enrich MikroTik CEF logs before they are stored in VictoriaLogs.

### RouterOS remote logging

Example RouterOS configuration:

```routeros
/system logging action add name=victorialogs target=remote remote=<collector-ip> remote-port=5515 bsd-syslog=yes syslog-facility=local0
/system logging add topics=info action=victorialogs
/system logging add topics=warning action=victorialogs
/system logging add topics=error action=victorialogs
/system logging add topics=critical action=victorialogs
```

Use the same port as `homelab.features.vector.cef.port`.

### Enriched fields

Firewall enrichment extracts fields such as:

- `mikrotik_firewall_message`
- `mikrotik_firewall_action`
- `mikrotik_firewall_chain`
- `mikrotik_firewall_in_interface`
- `mikrotik_firewall_out_interface`
- `mikrotik_firewall_connection_state`
- `mikrotik_firewall_src_mac`
- `mikrotik_firewall_ip_protocol_number`
- `mikrotik_firewall_src_ip`
- `mikrotik_firewall_src_port`
- `mikrotik_firewall_dst_ip`
- `mikrotik_firewall_dst_port`
- `mikrotik_firewall_packet_len`

Login enrichment extracts fields such as:

- `mikrotik_login_message`
- `mikrotik_login_user`
- `mikrotik_login_source_ip`
- `mikrotik_login_method`
- `risk_type = "mikrotik login"`

Login failures are marked as critical events.

DHCP enrichment extracts fields such as:

- `mikrotik_dhcp_message`
- `mikrotik_dhcp_server`
- `mikrotik_dhcp_action`
- `mikrotik_dhcp_ip`
- `mikrotik_dhcp_mac`
- `mikrotik_dhcp_hostname`
- `risk_type = "mikrotik dhcp"`

## Metrics

Vector exposes internal metrics through a local Prometheus exporter:

```text
127.0.0.1:10240/metrics
```

The module wires this automatically with:

```nix
services.vector.settings.sources.vector_internal_metrics = {
  type = "internal_metrics";
};

services.vector.settings.sinks.vector_prometheus_exporter = {
  type = "prometheus_exporter";
  inputs = [ "vector_internal_metrics" ];
  address = "127.0.0.1:10240";
};
```

It also publishes the VictoriaMetrics scrape integration:

```nix
homelab.integrations.services.vector.victoriametrics = {
  metrics_path = "/metrics";
  static_configs = [
    {
      targets = [ "127.0.0.1:10240" ];
      labels = {
        instance = config.networking.hostName;
        service = "vector";
      };
    }
  ];
};
```

`vmagent` turns this into the `vector` scrape job.

## Grafana

When Grafana is enabled, this feature provisions the Vector dashboard from:

```text
modules/nixos/features/vector/grafana_dashboard.json
```

The dashboard uses the default Grafana datasource. In this homelab, the
VictoriaMetrics datasource is provisioned as the default metrics datasource.

## Operations

### Service commands

```bash
@service-vector-status
@service-vector-journal
@service-vector-config
```

`@service-vector-config` validates the generated Vector YAML used by the
systemd service.

### Check the local metrics endpoint

```bash
curl http://127.0.0.1:10240/metrics
```

### Check the generated Vector service

```bash
systemctl cat vector
journalctl -u vector -b --no-pager -n 200
```

## Troubleshooting

### Vector does not start

Validate the generated configuration:

```bash
@service-vector-config
```

Common causes:

- CEF is enabled without `cef.listenInterfaces`
- VictoriaLogs forwarding is enabled without any enabled log source
- the UDP port is already used by another service

### Logs do not reach VictoriaLogs

Check that:

- `homelab.features.vector.victorialogs.enable = true`
- `homelab.features.victorialogs.enable = true`
- the Vector sink endpoint points to the correct VictoriaLogs port
- the router sends logs to the same UDP port configured by Vector

Useful commands:

```bash
journalctl -u vector -b --no-pager -n 200
journalctl -u victorialogs -b --no-pager -n 200
```

### Dashboard has no data

Check that VictoriaMetrics scrapes Vector:

```bash
systemctl cat vmagent
```

Look for a `job_name` named `vector` with target `127.0.0.1:10240`.

## Learn More

- [Vector Documentation](https://vector.dev/docs/)
- [Vector internal_metrics source](https://vector.dev/docs/reference/configuration/sources/internal_metrics/)
- [Vector prometheus_exporter sink](https://vector.dev/docs/reference/configuration/sinks/prometheus_exporter/)
- [VictoriaLogs Documentation](https://docs.victoriametrics.com/victorialogs/)
