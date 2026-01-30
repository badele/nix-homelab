<!-- BEGIN SECTION feature_informations file=./.templates/feature_blocky.html -->

<div class="feature-detail">
  <h1 id="blocky">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/blocky.png" width="64" height="64" alt="Blocky" style="vertical-align: middle; margin-right: 10px;"/>
    Blocky
  </h1>
  <h2>Basic Information</h2>
  <p>Fast and lightweight DNS proxy as ad-blocker for local network with many features</p>
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
        <td>0.27.0</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://0xerr0r.github.io/blocky">https://0xerr0r.github.io/blocky</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/blocky">modules/features/blocky</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is Blocky?

[Blocky](https://github.com/0xERR0R/blocky) is a fast and lightweight DNS proxy
and ad-blocker for local networks. Written in Go, it provides DNS-level blocking
with support for external blocklists and customizable filtering per client
group.

Blocky serves as a privacy-focused DNS resolver that blocks ads, trackers, and
malware at the network level without requiring client-side configuration.

![Blocky interface](../imgs/blocky.png)

## Why Use Blocky?

> Fast DNS proxy with network-wide ad blocking and privacy protection

**Key benefits:**

- **Network-Wide Blocking**: Block ads and trackers for all devices on the
  network
- **Customizable Lists**: Support for external blocklists (Ad-block, malware)
- **Client Groups**: Different blocking rules per device group (Kids, IoT, etc.)
- **Fast Performance**: Built-in caching and prefetching for quick DNS
  resolution
- **Modern Protocols**: DNS-over-HTTPS (DoH) and DNSSEC support
- **Stateless**: Single binary with no database or temporary files

## Learn More

- [Blocky GitHub Repository](https://github.com/0xERR0R/blocky)
- [Blocky Documentation](https://0xerr0r.github.io/blocky/latest/)
- [NixOS Wiki - Blocky](https://wiki.nixos.org/wiki/Blocky)
