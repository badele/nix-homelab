<!-- BEGIN SECTION feature_informations file=./.templates/feature_miniflux.html -->

<div class="feature-detail">
  <h1 id="miniflux">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/miniflux.png" width="64" height="64" alt="Miniflux" style="vertical-align: middle; margin-right: 10px;"/>
    Miniflux
  </h1>
  <h2>Basic Information</h2>
  <p>Minimalist and opinionated feed reader</p>
  <table>
    <tbody>
      <tr>
        <th>Category</th>
        <td>
<a href="/docs/all-features.md#essentials">Essentials</a>
        </td>
      </tr>
      <tr>
        <th>Platform</th>
        <td>nixos</td>
      </tr>
      <tr>
        <th>Version</th>
        <td>2.2.14</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://miniflux.app">https://miniflux.app</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/miniflux">modules/features/miniflux</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is Miniflux?

[Miniflux](https://miniflux.app/) is a minimalist and opinionated RSS feed
reader. Written in Go as a single binary, it provides a fast, privacy-focused
interface for reading and organizing feeds with minimal resource usage.

Miniflux supports full-text search, content scraping, media playback, and
integrates with 25+ third-party services via webhooks and APIs.

![Miniflux interface](../imgs/miniflux.png)

## Why Use Miniflux?

> Minimalist RSS reader with maximum privacy

**Key benefits:**

- **Lightweight**: Uses only a few MB of memory with negligible CPU usage
- **Privacy-Focused**: Removes pixel trackers, strips tracking URLs, no
  telemetry
- **Content Scraper**: Fetches full articles even from summary-only feeds
- **Full-Text Search**: PostgreSQL-powered search across all articles
- **Media Support**: Plays YouTube videos, podcasts, and attachments inline
- **25+ Integrations**: Linkding, Wallabag, Readwise, Telegram, and more
- **Multiple Auth**: Local, WebAuthn, OAuth2, OpenID Connect support

## Configuration

**Admin credentials:**

```bash
# Username: admin
# Password:
clan vars get houston miniflux/miniflux-env | grep ADMIN_PASSWORD | cut -d= -f2
```

## Troubleshooting

### Reset User Password

Set the database URL environment variable and use Miniflux CLI:

```bash
sudo -u miniflux bash
export DATABASE_URL="$(systemctl cat miniflux | grep DATABASE_URL | grep -oP '(?<=Environment="DATABASE_URL=).*(?=")')"
# Reset password for specific user
miniflux -reset-password <username>
```

### Fix "This User Already Exists" (OIDC)

If you encounter "This user already exists" when logging via OpenID Connect, the
OIDC ID is already linked to another account.

**Steps to fix:**

1. Get the user's UID from Authentik:
   - Login with admin account
   - Go to `https://douane.ma-cabane.eu/api/v3/core/users/?username=<USERNAME>`
   - Copy the `uid` value

2. Update the OpenID Connect ID in Miniflux:

```bash
sudo -u miniflux bash
AUTHENTIK_USERNAME="<USERNAME>"
AUTHENTIK_UID="<UID>"
psql miniflux -c "UPDATE users SET openid_connect_id='$AUTHENTIK_UID' WHERE username='$AUTHENTIK_USERNAME'"
```

## Learn More

- [Miniflux Official Website](https://miniflux.app/)
- [Miniflux GitHub Repository](https://github.com/miniflux/v2)
- [Miniflux Features](https://miniflux.app/features.html)
- [Miniflux CLI Documentation](https://miniflux.app/docs/cli.html)
