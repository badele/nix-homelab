## Architecture

[→ Learn more about Vector + VictoriaMetric + Reaction](../machines/houston/README.md#firewall-security-stack)

## command line

### List metrics

```bash
curl "http://localhost:8428/api/v1/label/__name__/values" | jq .
```

## Get metric

```bash
curl -s 'http://localhost:8428/api/v1/series?match[]=security_events_counter'
```

### Delete series

```bash
curl -X POST 'http://localhost:8428/api/v1/admin/tsdb/delete_series' -d 'match[]={__name__="vector_security_malicious_ips"}'
```
