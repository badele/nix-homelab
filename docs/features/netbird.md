<!-- BEGIN SECTION feature_informations file=./.templates/feature_netbird.html -->

<div class="feature-detail">
  <h1 id="netbird">
    <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/netbird.png" width="64" height="64" alt="NetBird" style="vertical-align: middle; margin-right: 10px;"/>
    NetBird
  </h1>
  <h2>Basic Information</h2>
  <p>WireGuard-based private mesh network with access controls</p>
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
        <td>0.72.4</td>
      </tr>
      <tr>
        <th>Site link</th>
        <td><a href="https://github.com/netbirdio/netbird">https://github.com/netbirdio/netbird</a></td>
      </tr>
      <tr>
        <th>Nix Homelab Module</th>
        <td><a href="../../modules/features/netbird">modules/features/netbird</a></td>
      </tr>
    </tbody>
  </table>
</div>

<!-- END SECTION feature_informations -->

## What is NetBird?

[NetBird](https://netbird.io/) is a WireGuard-based private network platform.
It provides a management plane, a signal service, TURN relay support, clients
for desktop and mobile devices, and access-control policies for peers and
network resources.

In this homelab, NetBird is used as a self-hosted alternative to Tailscale:

- `cab1e` hosts the public control plane.
- `constellation` runs a NetBird peer used as a gateway to selected VLANs.
- [ZITADEL](./zitadel.md) is used as the OIDC identity provider.

## Architecture

### Peer DNS domain

The feature configures the DNS suffix used by NetBird for peer resolution:

```nix
homelab.features.netbird.dnsDomain = "netbird.${config.homelab.domain}";
```

The NetBird overlay prefix is managed by NetBird itself. Copy the actual value
from `NetBird UI -> Settings -> Network` when configuring return routes.

### Public control plane

The public service runs on `cab1e`, the Hetzner instance.

```nix
homelab.features.netbird = {
  enable = true;

  public = {
    enable = true;
    serviceDomain = "netbird.${config.homelab.domain}";
    listenInterfaces = [ config.homelab.host.interface ];
    registerScope = [ "public" ];
    dnsTargetAddress = config.homelab.host.address;
    openFirewall = true;
  };

  auth = {
    provider = "zitadel";
    issuerURL = "https://douane.ma-cabane.eu";
    clientId = "<zitadel-client-id>";
    managementClientId = "<zitadel-management-client-id>";
  };
};
```

Caddy terminates HTTPS on port `443` for:

- dashboard
- management API
- management gRPC
- management WebSocket
- signal gRPC
- signal WebSocket
- NetBird relay WebSocket

Coturn is exposed directly. It does not pass through Caddy.

Advanced NetBird settings can be passed without duplicating every native NixOS
option:

```nix
homelab.features.netbird.public = {
  management = {
    settings = { };
    extraOptions = [ ];
  };

  signal.extraOptions = [ ];

  dashboard.settings = { };
};
```

These values are merged into `services.netbird.server.management`,
`services.netbird.server.signal`, and `services.netbird.server.dashboard`.

The feature follows the NetBird ZITADEL standalone documentation and requests:

```text
openid profile email offline_access api
```

### Private gateway

The private gateway runs on `constellation`.

```nix
homelab.features.netbird = {
  enable = true;

  clients.infra = {
    enable = false;
    interface = "nb-infra";
    managementURL = "https://metro.ma-cabane.eu";
    portOffset = 0;
    listenInterfaces = [ "br-lan" ];
    openFirewall = true;
    environment = { };
    config = { };

    gateway = {
      enable = true;
      networks = [ "192.168.244.0/24" ];
      # Alternative or complement:
      # vlans = [ "infra" ];
      routingFeatures = "server";
    };
  };
};
```

Use `enable = false` during the first bootstrap so Clan does not ask for a
setup key before the NetBird control plane exists. After `cab1e` is deployed
and the setup key has been created in NetBird, set `enable = true` or provide
`setupKeyFile`.

The gateway opens only its NetBird WireGuard UDP port on the configured
interfaces. Access to VLAN resources is then controlled in NetBird with
Networks, Groups, and Policies.

`gateway.vlans` can be used to reference entries from `homelab.vlans`. The
feature also infers VLANs when a gateway network matches the convention
`192.168.<vlan id>.0/24`.

Client passthroughs are merged into `services.netbird.clients.<name>`:

- `environment` adds NetBird environment variables.
- `config` adds NetBird client JSON configuration.

The `managementURL` option is written both as `NB_MANAGEMENT_URL` and as the
persistent client `ManagementURL` object, so a redeploy updates existing peers
when the control plane domain changes.

The feature still forces the native NetBird client firewall off and opens the
WireGuard UDP port through `networking.firewall.interfaces` instead.

## Ports

The feature uses `homelab.portRegistry.netbird.appId = 250`.

| Service                 |            Port | Scope                     |
| ----------------------- | --------------: | ------------------------- |
| Caddy HTTPS             |         443/tcp | public `listenInterfaces` |
| Management API          |       10250/tcp | localhost                 |
| Signal gRPC             |       10251/tcp | localhost                 |
| Management metrics      |       10252/tcp | localhost                 |
| Signal metrics          |       10253/tcp | localhost                 |
| STUN/TURN               |   10254/tcp+udp | public `listenInterfaces` |
| TURN relay range        | 10255-10335/udp | public `listenInterfaces` |
| NetBird relay WebSocket |       10336/tcp | localhost via Caddy       |
| Relay metrics           |       10337/tcp | localhost                 |
| Client `portOffset = 0` |       20250/udp | client `listenInterfaces` |

TURN TLS/DTLS is disabled in this setup. NetBird advertises `turn:` and
`stun:` endpoints, not `turns:`. The relayed peer traffic remains encrypted by
WireGuard.

The NetBird relay is distinct from coturn. It is advertised to peers as
`rels://<service-domain>:443` and is proxied by Caddy to the local
`netbird-relay` service.

## ZITADEL OIDC

The NetBird feature does not provision the ZITADEL project or application.
Create them manually in ZITADEL, then put the values in Nix and Clan vars.
This feature follows NetBird's standalone ZITADEL setup, where ZITADEL is the
primary identity provider.
Reference:
[Zitadel with NetBird Self-Hosted](https://docs.netbird.io/selfhosted/identity-providers/zitadel).
[Zitadel SSO with NetBird Self-Hosted (Advanced)](https://docs.netbird.io/selfhosted/identity-providers/advanced/zitadel).

### ZITADEL objects

NetBird needs three distinct ZITADEL objects:

- Project: `NetBird`
- OIDC application: `netbird SSO`
- Service user: `netbird`

Keep these names distinct when copying values into Nix or Clan vars.

### Create the NetBird project

Create a project named `NetBird`.

### Create the netbird SSO application

Create the `netbird SSO` OIDC application in the `NetBird` project. This
application is used by the NetBird dashboard and clients for user login.

#### Configure the application

- Application Type: `User Agent`
- Response Types:
  - `Code`
- Authentication Method: `None`
  - If your ZITADEL version explicitly offers `PKCE`, select `PKCE` instead.
  - This is the public-client PKCE mode: the application does not use a client
    secret.
- Redirect URIs:
  - `http://localhost:53000`
  - `https://metro.ma-cabane.eu/auth`
  - `https://metro.ma-cabane.eu/silent-auth`
- Post Logout URI:
  - `https://metro.ma-cabane.eu/`
- Grant Types:
  - `Authorization Code`
  - `Device Code`
  - `Refresh Token`

ZITADEL can report an OIDC compliance warning because `http://localhost:53000`
is not an HTTPS redirect URI. Keep this URI because NetBird clients use it for
local browser-based login, and enable `Development Mode` in the application's
redirect settings if ZITADEL rejects it.

For the NetBird management configuration, keep `http://localhost:53000` before
the dashboard callbacks. Native clients choose the first usable PKCE redirect
URL; if the dashboard callback is first, Android can open the ZITADEL login but
fail to return the authentication result to the NetBird app.

#### Configure token settings

After the application is created, open the `netbird SSO` application details
and configure `Token Settings`. These settings are required for native clients
such as Android:

- Auth Token Type: `JWT`
- Enable `Add user roles to the access token`.
- If token validation fails later, also enable user information in the ID token
  for this application.

Without a JWT access token, Android can complete the browser login and then
fail while validating the returned token.

Copy the `netbird SSO` application client ID into:

```nix
homelab.features.netbird.auth.clientId = "<zitadel-client-id>";
```

In the `NetBird` project settings, enable `Assert Roles on Authentication`.
This makes ZITADEL user grants available to the `groupsClaim` action.

#### Create the management service user in ZITADEL

NetBird also uses a ZITADEL service user to cache and synchronize IdP users.
This is not the `netbird SSO` application.

1. Open `Users`.
2. Select the `Service Users` tab.
3. Create a service user:
   - User Name: `netbird`
   - Name: `netbird`
   - Description: `NetBird Service User`
   - Access Token Type: `JWT`
4. Open `Actions`.
5. Select `Generate Client Secret`.
6. Copy the generated `ClientSecret`.
7. Paste it when Clan vars asks for:

```text
Please insert the ZITADEL service user ClientSecret for NetBird:
```

The prompt stores the value in:

```text
netbird-zitadel-service-user/client-secret
```

This prompt generator is shared across machines because the ZITADEL service user
`ClientSecret` is the same for every NetBird control plane using this identity
provider.

The main `netbird` generator then copies the same value into:

```text
netbird/management-client-secret
```

That final path is machine-local and consumed by the NetBird management service.
Other `netbird/*` secrets, such as TURN and datastore encryption secrets, remain
machine-local.

Then grant the required ZITADEL role:

1. Open `Organization`.
2. Add an authorization for the `netbird` service user. (click on `+` on top-right)
3. Select the `Org User Manager` role.

```nix
homelab.features.netbird.auth = {
  managementClientId = "netbird";
  managementClientSecretFile = /run/secrets/netbird-zitadel-management-secret;
};
```

#### Configure the groupsClaim action

NetBird can synchronize groups from a JWT claim named `groups`. ZITADEL exposes
project roles, so add this ZITADEL action to copy user grant roles into the
`groups` claim:

```js
/**
 * Sets the roles as an additional claim in the token with "groups" as the key.
 *
 * Flow: Complement token
 * Triggers: Pre Userinfo creation, Pre access token creation
 */
function groupsClaim(ctx, api) {
  if (ctx.v1.user.grants === undefined || ctx.v1.user.grants.count == 0) {
    return;
  }

  let grants = [];
  ctx.v1.user.grants.grants.forEach((claim) => {
    claim.roles.forEach((role) => {
      grants.push(role);
    });
  });

  api.v1.claims.setClaim("groups", grants);
}
```

Assign ZITADEL project roles to users. The role names are copied as-is into the
`groups` claim, so a ZITADEL role named `user` becomes a NetBird synchronized
group named `user`. Role names are case-sensitive.

In NetBird, enable JWT group synchronization:

1. Open `Settings` -> `Groups`.
2. Enable JWT group synchronization.
3. Set the JWT claim name to `groups`.
4. Log out and log back in through ZITADEL so NetBird receives a fresh token.

### Groups and policies

Use ZITADEL roles and NetBird synchronized groups to model least privilege. The
same name should be used on both sides because the `groupsClaim` action copies
roles without renaming them.

Do not rely on the Linux firewall to distinguish family, user, and admin
roles. The gateway firewall allows traffic from the NetBird interface to the
selected VLAN interface; the role-level access control must be done in NetBird
Policies.

## NetBird setup

After the control plane is deployed:

1. Log in to `https://metro.ma-cabane.eu`.
2. Complete the initial NetBird wizard with `Remote Network Access`.
3. When the wizard asks for a client, install NetBird on a desktop or mobile
   device and log in with ZITADEL.
4. Wait until this first user peer appears connected in the NetBird web UI.
5. In the NetBird web UI, create setup keys for the gateway peers.
6. Set the gateway client `enable = true`, or provide `setupKeyFile`.
7. During deployment, enter the setup key prompted by Clan vars if no file was
   provided.
8. Create a `Remote Network Access` resource.
9. Select `Define Entire Subnet`.
10. Name the resource `infra` and set the subnet to `192.168.244.0/24`.
11. Select the `constellation` / `nb-infra` peer as routing peer.
12. Create Policies from user groups to the allowed resources.
13. Disable or restrict any permissive default policy.

The first client requested by the wizard is only used to finish the NetBird
instance onboarding. The `constellation` / `nb-infra` peer remains the gateway
used to route traffic to the infra VLAN.

Use `Remote Network Access` when exposing a VLAN or subnet through a NetBird
gateway peer. Use peer-to-peer access only for direct communication between
devices that both run a NetBird client.

For route return on MikroTik, add a route from the VLAN gateway back to the
NetBird overlay prefix:

```bash
/ip route add dst-address=<netbird-overlay-prefix> gateway=<br-infra-address> comment="NetBird overlay via constellation/infra"
```

Replace `<netbird-overlay-prefix>` with the value shown in
`NetBird UI -> Settings -> Network`.
Replace `<br-infra-address>` with the `constellation` address on the infra VLAN.

The current gateway firewall rules allow traffic from the NetBird interface to
the selected VLAN bridge and allow established return traffic. They do not
differentiate NetBird users. User-level access must be enforced with NetBird
Policies.

## Operations

Useful commands:

```bash
@service-netbird-management-status
@service-netbird-management-journal
@service-netbird-signal-status
@service-netbird-signal-journal
@service-netbird-relay-status
@service-netbird-relay-journal
@service-netbird-coturn-status
@service-netbird-coturn-journal
```

Check local Prometheus metrics endpoints:

```bash
curl http://127.0.0.1:10252/metrics
curl http://127.0.0.1:10253/metrics
curl http://127.0.0.1:10337/metrics
```

VictoriaMetrics automatically scrapes these endpoints through
`homelab.integrations.services.netbird.victoriametrics`.

Grafana provisions the local NetBird dashboards from
`modules/nixos/features/netbird/grafana/dashboards` in the `NetBird` folder.
These dashboards are maintained in this repository.

On a client peer:

```bash
systemctl status netbird-infra
journalctl -u netbird-infra
```

To inspect the NetBird daemon state from a NixOS client without installing the
CLI globally:

```bash
nix shell nixpkgs#netbird
env NB_DAEMON_ADDR=unix:///var/run/netbird-infra/sock netbird status -d
```

The output should include the relay endpoint:

```text
[rels://metro.ma-cabane.eu:443] is Available
```

### Android Debugging

Use Android wireless debugging to inspect the NetBird client logs when a mobile
peer appears online in the UI but stays in `Connecting` from other peers.

On the Android device:

1. Open the Android settings.
2. Tap the build number 7 times to enable developer options.
3. Enable wireless debugging.
4. Open the wireless debugging pairing screen and note the pairing host/port.
5. After pairing, note the separate connection host/port.

On a NixOS workstation:

```bash
nix shell nixpkgs#android-tools
adb pair <android-ip>:<pairing-port>
adb connect <android-ip>:<debug-port>
adb logcat | grep -Ei 'netbird|relay|stun|turn|wireguard|ice'
```

The pairing port and the debug connection port are different. Use the pairing
port only with `adb pair`, then use the debug port with `adb connect`.

## Limitations

- NetBird handles Layer 3 routing, not Layer 2 bridging.
- NetBird Networks and Policies are configured manually in the UI/API for now.
- ZITADEL OIDC applications are created manually for now.
- Direct `services.netbird.*` overrides can bypass homelab conventions such as
  interface-scoped firewall rules.
- Self-signed TURN certificates are not used, to keep Android, iOS, Windows,
  and family devices simple.

## Learn More

- [NetBird Documentation](https://docs.netbird.io/)
- [NetBird Self-hosted Guide](https://docs.netbird.io/selfhosted/selfhosted-guide)
- [NetBird Network Resources](https://docs.netbird.io/manage/networks)
- [NetBird Routing Peers](https://docs.netbird.io/manage/networks/how-routing-peers-work)
- [NetBird Access Control](https://docs.netbird.io/manage/access-control)
- [NetBird Client Profiles](https://docs.netbird.io/client/profiles)
