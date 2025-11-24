# Features

nix-homelab fourni des modules qui interagisse entre eux (générallement
localement) sans devoir configurer chaque servvice.

Voici une liste des applications ou services que nix-homelab propose

<!-- BEGIN SECTION all_features file=./.templates/generate_all_available_features_table.html -->

<h2 id="core-services">Core Services</h2>
<table>
  <thead>
    <tr>
      <th>Icon</th>
      <th>Service Name</th>
      <th>Platform</th>
      <th>Version</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@master/webp/lets-encrypt.webp" width="48" height="48" alt="ACME"/>
      </td>
      <td>
        <a href="/docs/features/acme.md">ACME 📚</a>
      </td>
      <td>nixos</td>
      <td>4.27.0</td>
      <td>Let's Encrypt client and ACME library written in Go</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authentik.png" width="48" height="48" alt="authentik"/>
      </td>
      <td>
        <a href="/docs/features/authentik.md">authentik 📚</a>
      </td>
      <td>nixos</td>
      <td>2025.10.12</td>
      <td>The authentication glue you need. </td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/blocky.png" width="48" height="48" alt="Blocky"/>
      </td>
      <td>
        <a href="/docs/features/blocky.md">Blocky 📚</a>
      </td>
      <td>nixos</td>
      <td>0.27.0</td>
      <td>Fast and lightweight DNS proxy as ad-blocker for local network with many features</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/goaccess.png" width="48" height="48" alt="GoAccess"/>
      </td>
      <td>
        <a href="/docs/features/goaccess.md">GoAccess 📚</a>
      </td>
      <td>nixos</td>
      <td>1.9.4</td>
      <td>Real-time web log analyzer and interactive viewer that runs in a terminal in *nix systems</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homebox.png" width="48" height="48" alt="Nix homelab summary"/>
      </td>
      <td>
        <a href="https://github.com/badele/nix-homelab">Nix homelab summary</a>
      </td>
      <td>nixos</td>
      <td></td>
      <td>Generate a static HTML summary of your Nix homelab instance</td>
    </tr>
  </tbody>
</table>

<h2 id="essentials">Essentials</h2>
<table>
  <thead>
    <tr>
      <th>Icon</th>
      <th>Service Name</th>
      <th>Platform</th>
      <th>Version</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/dokuwiki.png" width="48" height="48" alt="DokuWiki"/>
      </td>
      <td>
        <a href="/docs/features/dokuwiki.md">DokuWiki 📚</a>
      </td>
      <td>podman</td>
      <td>version-2025-05-14b</td>
      <td>Simple to use and highly versatile wiki software</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/grist.png" width="48" height="48" alt="grist"/>
      </td>
      <td>
        <a href="/docs/features/grist.md">grist 📚</a>
      </td>
      <td>podman</td>
      <td>1.7.7</td>
      <td>Next generation of spreadsheets</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/it-tools.png" width="48" height="48" alt="it-tools"/>
      </td>
      <td>
        <a href="/docs/features/it-tools.md">it-tools 📚</a>
      </td>
      <td>podman</td>
      <td>2025.10.12</td>
      <td>Collection of handy online tools for developers, with great UX</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/linkding.png" width="48" height="48" alt="Linkding"/>
      </td>
      <td>
        <a href="/docs/features/linkding.md">Linkding 📚</a>
      </td>
      <td>podman</td>
      <td>1.41.0-plus</td>
      <td>Bookmark manager designed to be minimal, fast, and easy to set up</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/miniflux.png" width="48" height="48" alt="Miniflux"/>
      </td>
      <td>
        <a href="/docs/features/miniflux.md">Miniflux 📚</a>
      </td>
      <td>nixos</td>
      <td>2.2.14</td>
      <td>Minimalist and opinionated feed reader</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://radio.0cx.de/static/parrot.gif" width="48" height="48" alt="Radio"/>
      </td>
      <td>
        <a href="/docs/features/radio.md">Radio 📚</a>
      </td>
      <td>nixos</td>
      <td>20251119</td>
      <td>Internet Radio</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/podman.png" width="48" height="48" alt="Sample Podman application"/>
      </td>
      <td>
        <a href="https://github.com/badele/nix-homelab">Sample Podman application</a>
      </td>
      <td>podman</td>
      <td>2025-09-28-alpine</td>
      <td>Sample podman application with hardening options.</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/shaarli.png" width="48" height="48" alt="Shaarli"/>
      </td>
      <td>
        <a href="https://github.com/shaarli/Shaarli">Shaarli</a>
      </td>
      <td>podman</td>
      <td>v0.12.2</td>
      <td>Personal, minimalist, super-fast, database free, bookmarking service - community repo</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@master/webp/wastebin.webp" width="48" height="48" alt="Wastebin"/>
      </td>
      <td>
        <a href="https://github.com/matze/wastebin">Wastebin</a>
      </td>
      <td>nixos</td>
      <td>3.3.0</td>
      <td>Pastebin service</td>
    </tr>
  </tbody>
</table>

<h2 id="system-health">System Health</h2>
<table>
  <thead>
    <tr>
      <th>Icon</th>
      <th>Service Name</th>
      <th>Platform</th>
      <th>Version</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gatus.png" width="48" height="48" alt="Gatus"/>
      </td>
      <td>
        <a href="https://gatus.io">Gatus</a>
      </td>
      <td>nixos</td>
      <td>5.31.0</td>
      <td>Automated developer-oriented status page</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/grafana.png" width="48" height="48" alt="Grafana"/>
      </td>
      <td>
        <a href="https://grafana.com">Grafana</a>
      </td>
      <td>nixos</td>
      <td>12.2.1</td>
      <td>Gorgeous metric viz, dashboards & editors for Graphite, InfluxDB & OpenTSDB</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png" width="48" height="48" alt="Homepage"/>
      </td>
      <td>
        <a href="https://gethomepage.dev">Homepage</a>
      </td>
      <td>nixos</td>
      <td>1.5.0</td>
      <td>Highly customisable dashboard with Docker and service API integrations</td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/victoriametrics.png" width="48" height="48" alt="Victoriametrics"/>
      </td>
      <td>
        <a href="https://victoriametrics.com/">Victoriametrics</a>
      </td>
      <td>nixos</td>
      <td>1.129.1</td>
      <td>Fast, cost-effective and scalable time series database, long-term remote storage for Prometheus</td>
    </tr>
  </tbody>
</table>


---

<h2 id="deprecated-services">Deprecated Services</h2>
<table>
  <thead>
    <tr>
      <th>Icon</th>
      <th>Service Name</th>
      <th>Category</th>
      <th>Platform</th>
      <th>Description</th>
      <th>Deprecation Notice</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/authelia.png" width="48" height="48" alt="Authelia"/>
      </td>
      <td>
        <a href="/docs/features/authelia.md">Authelia 📚</a>
      </td>
      <td>Core Services</td>
      <td>nixos</td>
      <td>Single Sign-On multi-factor portal for web apps</td>
      <td><em>Migrated from Authelia to Authentik. While Authentik requires some manual configuration, it offers more features and better integration capabilities.
// https://github.com/badele/nix-homelab/docs/features/authentik.md
</em></td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kanidm.png" width="48" height="48" alt="Kanidm"/>
      </td>
      <td>
        <a href="/docs/features/kanidm.md">Kanidm 📚</a>
      </td>
      <td>Core Services</td>
      <td>nixos</td>
      <td>Simple, secure and fast identity management platform</td>
      <td><em>While lightweight and performant, Kanidm requires manual configuration for some operations. Migrated to Authentik for better web UI.
</em></td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lldap.png" width="48" height="48" alt="LLDAP"/>
      </td>
      <td>
        <a href="/docs/features/lldap.md">LLDAP 📚</a>
      </td>
      <td>Core Services</td>
      <td>nixos</td>
      <td>Lightweight authentication server that provides an opinionated, simplified LDAP interface for authentication</td>
      <td><em>Previously used LLDAP with Authelia, now migrated to Authentik. Authentik provides built-in user management and more integrated features, eliminating the need for a separate LDAP server.
</em></td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://prahec.com/projects/pawtunes/demo/assets/img/apple-touch-icon.png" width="48" height="48" alt="Pawtunes"/>
      </td>
      <td>
        <a href="/docs/features/pawtunes.md">Pawtunes 📚</a>
      </td>
      <td>Essentials</td>
      <td>podman</td>
      <td>The Ultimate HTML5 Internet Radio Player</td>
      <td><em>This feature is deprecated due to Docker image initialization complexity.

Recommended alternative: Use the simpler Radio application which provides
a lightweight internet radio player without the Docker initialization overhead
// https://github.com/badele/nix-homelab/docs/features/radio.md

</em></td>
    </tr>
    <tr>
      <td align="center">
        <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/step-ca.png" width="48" height="48" alt="Step CA"/>
      </td>
      <td>
        <a href="/docs/features/step-ca.md">Step CA 📚</a>
      </td>
      <td>Core Services</td>
      <td>nixos</td>
      <td>Private certificate authority (X.509 & SSH) & ACME server for secure automated certificate management, so you can use TLS everywhere & SSO for SSH</td>
      <td><em>This feature is deprecated. While it works fine, it has significant limitations:
it's difficult to add the self-signed CA to all devices. For example, Firefox
on Android doesn't use the Android root CA store.

Recommended alternative: Use public domain names (with private IPs) and DNS-01
challenge for automated certificate management with Let's Encrypt.
</em></td>
    </tr>
  </tbody>
</table>

<!-- END SECTION all_features -->
