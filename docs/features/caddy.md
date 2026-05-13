<!-- BEGIN SECTION feature_informations file=./.templates/feature_caddy.html -->

<div class="feature-detail">
  <h1 id="caddy">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/caddy.png" width="64" height="64" alt="Caddy" style="vertical-align: middle; margin-right: 10px;"/>
    Caddy
  </h1>
  <h2>Basic Information</h2>
  <p>Fast and extensible web server with automatic HTTPS</p>
  <table>
    <tbody>
      <tr>
        <th>Category</th>
        <td>
<a href="/docs/all-features.md#core-services">Core Services</a>
        </td>
      </tr>
      <tr>
        <th>Platform</th>
        <td>nixos</td>
      </tr>
      <tr>
        <th>Version</th>
        <td>2.11.2</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://caddyserver.com/">https://caddyserver.com/</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/caddy">modules/features/caddy</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is Caddy?

[Caddy](https://caddyserver.com/) is a modern web server and reverse proxy with
automatic HTTPS. In this homelab, Caddy is used as the public HTTPS entrypoint
for services exposed with `services.caddy.virtualHosts`.

The module configures Caddy with the Hetzner DNS plugin so certificates can be
issued through DNS-01 challenges.

## Why Use Caddy?

> Automatic HTTPS with DNS-01 certificates and simple reverse proxying

**Key benefits:**

- **Automatic Certificates**: Caddy obtains and renews HTTPS certificates
  automatically
- **DNS-01 Support**: Hetzner DNS challenges work without opening HTTP port `80`
- **Reverse Proxy**: Public domains proxy to local services listening on
  `127.0.0.1`
- **Centralized Logs**: Public access logs are written as JSON for GoAccess and
  observability

## Configuration

### Enable the feature

```nix
homelab.features = {
  acme.enable = true;
  acme.email = config.homelab.domainEmailAdmin;
  acme.dnsProvider = "hetzner";

  caddy.enable = true;
};
```

### Hetzner DNS challenge

The Caddy module builds Caddy with the Hetzner DNS provider:

```nix
package = pkgs.caddy.withPlugins {
  plugins = [ "github.com/caddy-dns/hetzner/v2@v2.0.0" ];
  hash = "sha256-pQJ4X7o8Z2Ra2OteMrzP7guWcxBe4zfn8jFwIAdQ+Ow=";
};
```

The Hetzner API token is stored through Clan vars and exposed to Caddy as:

```env
HETZNER_API_TOKEN=<token>
```

### DNS propagation

The module uses the authoritative Hetzner nameservers for propagation checks:

```caddyfile
cert_issuer acme {
  dns hetzner {$HETZNER_API_TOKEN}
  propagation_delay 60s
  propagation_timeout 10m
  resolvers 213.133.100.102 213.239.204.242 193.47.99.4
}
auto_https disable_redirects
```

`auto_https disable_redirects` disables only the automatic HTTP-to-HTTPS
redirect listener. HTTPS certificate management remains enabled.

## Virtual Hosts

Each public service declares its own Caddy virtual host. Example:

```nix
services.caddy.virtualHosts = mkIf cfg.openFirewall {
  "${cfg.serviceDomain}" = {
    logFormat = ''
      output file /var/log/caddy/public.log {
        mode 0644
      }
      format json
    '';

    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString listenHttpPort}
    '';
  };
};
```

The application container or service should keep listening locally, usually on
`127.0.0.1:<port>`. Caddy handles the public TLS endpoint.

## Troubleshooting

### Check that Caddy is running

```bash
systemctl status caddy
journalctl -u caddy -b --no-pager -n 200
```

### Check that the Hetzner plugin is available

```bash
caddy list-modules | grep hetzner
```

Expected module:

```text
dns.providers.hetzner
```

### Check certificate issuance

```bash
journalctl -u caddy -b | grep tls.obtain
```

Common DNS-01 error:

```text
NXDOMAIN looking up TXT for _acme-challenge.<domain>
```

This means Let's Encrypt did not see the DNS challenge TXT record. Check that:

- the Hetzner token is valid
- the token can write to the correct DNS zone
- the domain uses the expected Hetzner authoritative nameservers
- propagation delay is long enough for secondary validation

### Test from a client

```bash
curl -v https://example.ma-cabane.eu/
openssl s_client -connect example.ma-cabane.eu:443 -servername example.ma-cabane.eu
```

If the TLS handshake returns `tlsv1 alert internal error`, Caddy is usually
reachable on `:443` but cannot present a valid certificate yet. Check
`journalctl -u caddy` for the ACME error.

## Learn More

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddy Automatic HTTPS](https://caddyserver.com/docs/automatic-https)
- [Caddy DNS Challenge](https://caddyserver.com/docs/caddyfile/directives/tls#dns_challenge)
- [Caddy Hetzner DNS Plugin](https://github.com/caddy-dns/hetzner)
