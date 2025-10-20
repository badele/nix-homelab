# 🏠 nix-homelab

<img width="100%" src="./docs/imgs/nixos.gif" />

My personal homelab infrastructure, fully managed with
[NixOS](https://nixos.org/) and [Clan](./docs/clan.md). This repository contains
all configurations for my servers, desktops, and network devices.

## What is this?

This is a complete NixOS homelab setup that manages:

- **Servers**: Public VPS (Hetzner, Infomaniak), physical servers, Raspberry Pi
- **Desktops**: Personal laptops and workstations
- **Network**: Routers, IoT devices, and monitoring

Everything is declarative, reproducible, and version-controlled whenever
possible.

## Why Clan?

I'm using [Clan](./docs/clan.md) to simplify infrastructure management:

> Backbone of independent infrastructure

Or as I like to say:

> Kill the cloud, build your darkcloud ☁️

**[→ Learn more about Clan and why I use it](./docs/clan.md)**

### Key benefits

- **Simple host management**: Easy inventory system
- **Automatic secrets**: Built-in secret generation and management
- **Backup made easy**: Integrated backup solution
- **Declarative**: Everything in code, no manual steps

## 🛠️ Deployment Strategy

I follow a hybrid approach:

- **NixOS services first**: Most applications run as native NixOS services
- **Podman when needed**: Some apps use containers to:
  - Avoid service interruptions during system updates
  - Use plugins or features not well-supported in NixOS (e.g., DokuWiki)
  - Maintain stability during version upgrades

This gives me the best of both worlds: NixOS reproducibility with container
flexibility.

## Project Structure

> [!NOTE]
> 🚧 Work in Progress - The project is being migrated to Clan architecture.
> During this transition, you'll find both old and new directory structures
> coexisting.

The homelab uses a modular flake-parts architecture with Clan: **Key
directories:**

#### 🚧 New structure (managed with clan command)

- `machines/`: Per-host configurations `clan machines update "machine-name"`
- `modules/`: Shared modules and legacy configurations
- `vars/`: Secrets `clan vars list "machine-name"` and on nix expression
  `clan.core.vars.generators."secret-bucket-name"`

#### 💥 Legacy structure

- `nix/nixos/roles/`: Service roles
- `nix/home-manager/`: User environment configs
- `sops/`: SOPS secrets

## 📦 Services & Applications

Here are the main services running in my homelab:

[comment]: (>>ROLES)

<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>Type</th>
        <th>Links</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img width="32" src="https://www.kevinsubileau.fr/wp-content/uploads/2016/03/letsencrypt-logo-pad.png"></td>
        <td><a href="https://letsencrypt.org/fr/docs/client-options/">ACME</a></td>
        <td>NixOS</td>
        <td><a href="./docs/acme.md">doc</a></td>
        <td>rpi40, bootstore, houston</td>
        <td>Let's Encrypt Automatic Certificate Management Environment</td>
    </tr>
    <tr>
        <td><a href="./docs/authelia.md"><img width="32" src="https://www.authelia.com/favicon.svg"></a></td>
        <td><a href="https://www.authelia.com/">Authelia</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/authelia.nix">module</a>, <a href="./docs/authelia.md">doc</a></td>
        <td>houston</td>
        <td>An open-source authentication and single sign-on (SSO)</td>
    </tr>
    <tr>
        <td><a href="./docs/dokuwiki.md"><img width="32" src="https://www.dokuwiki.org/lib/tpl/dokuwiki/images/favicon.ico"></a></td>
        <td><a href="https://www.dokuwiki.org/">Dokuwiki</a></td>
        <td>Podman</td>
        <td><a href="./machines/houston/modules/dokuwiki.nix">module</a>, <a href="./docs/dokuwiki.md">doc</a></td>
        <td>houston</td>
        <td>Simple to use and highly versatile Open Source wiki software</td>
    </tr>
    <tr>
        <td><a href="https://goaccess.io/"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg"></a></td>
        <td><a href="https://goaccess.io/">GoAccess</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/goaccess.nix">module</a></td>
        <td>houston</td>
        <td>Real-time web log analyzer</td>
    </tr>
    <tr>
        <td><a href="./docs/grafana.md"><img width="32" src="https://grafana.com/static/assets/img/fav32.png"></a></td>
        <td><a href="https://grafana.com/">Grafana</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/grafana.nix">module</a>, <a href="./docs/grafana.md">doc</a></td>
        <td>houston</td>
        <td>The open and composable observability and data visualization platform [service port 3000]</td>
    </tr>
    <tr>
        <td><a href="./docs/linkding/README.md"><img width="32" src="https://linkding.link/favicon.svg"></a></td>
        <td><a href="https://linkding.link/">linkding</a></td>
        <td>Podman</td>
        <td><a href="./machines/houston/modules/linkding.nix">module</a></td>
        <td>houston</td>
        <td>Bookmark manager</td>
    </tr>
    <tr>
        <td><a href="https://goaccess.io/"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg"></a></td>
        <td><a href="https://github.com/lldap/lldap">LLDAP</a></td>
        <td>Podman</td>
        <td><a href="./machines/houston/modules/lldap.nix">module</a>, <a href="./docs/lldap.md">doc</a></td>
        <td>houston</td>
        <td>Lightweight LDAP directory service for authentication</td>
    </tr>
    <tr>
        <td><img width="32" src="https://reaction.ppom.me/favicon.svg"></td>
        <td><a href="https://reaction.ppom.me/">Reaction</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/reaction.nix">module</a>, <a href="./docs/reaction.md">doc</a></td>
        <td>houston</td>
        <td>Block some network attacks</td>
    </tr>
    <tr>
        <td><img width="32" src="https://vector.dev/favicon.ico"></td>
        <td><a href="https://vector.dev/">Vector</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/vector/default.nix">module</a>, <a href="./docs/reaction.md">doc</a></td>
        <td>houston</td>
        <td>High-performance observability data pipeline</td>
    </tr>
    <tr>
        <td><a href="./docs/victoriametrics.md"><img width="32" src="https://victoriametrics.com/icons/favicon.ico"></a></td>
        <td><a href="https://victoriametrics.com/">VictoriaMetrics</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/victoriametrics.nix">module</a>, <a href="./docs/victoriametrics.md">doc</a></td>
        <td>houston</td>
        <td>Fast and scalable time series database</td>
    </tr>
    <tr>
        <td><img width="32" src="https://bin.bloerg.net/favicon.ico"></td>
        <td><a href="https://github.com/matze/wastebin">Wastebin</a></td>
        <td>NixOS</td>
        <td><a href="./machines/houston/modules/wastebin.nix">module</a></td>
        <td>houston</td>
        <td>Minimalist pastebin</td>
    </tr>
</table>

[comment]: (<<ROLES)

## 💻 Desktop Environment

My workstations run a customized NixOS setup with i3 window manager and various
productivity tools.

### Desktop Applications

| Logo                                                                                                                                                                                      | Application | Description                                                                 |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------------- |
| [<img width="32" src="https://www.borgbackup.org/favicon.ico">](./docs/borgbackup/README.md)                                                                                              | borgbackup  | [Deduplication backup tool](./docs/borgbackup/README.md)                    |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Firefox_logo%2C_2019.svg/32px-Firefox_logo%2C_2019.svg.png">](./users/badele/firefox.nix)                 | Firefox     | [Web browser](./users/badele/firefox.nix)                                   |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/The_GIMP_icon_-_gnome.svg/32px-The_GIMP_icon_-_gnome.svg.png">](./users/badele/commons.nix)               | Gimp        | [Raster graphics editor](./users/badele/commons.nix)                        |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/I3_window_manager_logo.svg/32px-I3_window_manager_logo.svg.png">](./users/badele/commons.nix)             | i3          | [Tiling window manager](./nix/home-manager/features/desktop/xorg/wm/i3.nix) |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Inkscape_Logo.svg/32px-Inkscape_Logo.svg.png">](./users/badele/commons.nix)                               | Inkscape    | [Vector graphics editor](./users/badele/commons.nix)                        |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/LibreOffice_icon_3.3.1_48_px.svg/32px-LibreOffice_icon_3.3.1_48_px.svg.png">](./users/badele/commons.nix) | LibreOffice | [Office suite](./users/badele/commons.nix)                                  |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Meld_Logo.svg/128px-Meld_Logo.svg.png">](./users/badele/commons.nix)                                      | Meld        | [Visual diff tool](./users/badele/commons.nix)                              |
| [<img width="32" src="https://raw.githubusercontent.com/denisidoro/navi/master/assets/icon.png">](./nix/home-manager/features/term/base.nix)                                              | Navi        | [Interactive cheatsheet tool](https://github.com/badele/vide)               |
| [<img width="32" src="https://user-images.githubusercontent.com/28633984/66519056-2e840c80-eaef-11e9-8670-c767213c26ba.png">](https://github.com/badele/vide)                             | Neovim      | [**VIDE** - My customized Neovim config](/docs/nvim/README.md)              |

### Floating TUI Panels

Quick access to system controls via i3 floating terminals:

| Bluetooth Manager                                                                      | Disk Manager                                                                 |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [<img width="320" src="./docs/floating_bluetooth.png">](./docs/floating_bluetooth.gif) | [<img width="320" src="./docs/floating_disk.png">](./docs/floating_disk.gif) |
| `bluetuith`                                                                            | `bashmount`                                                                  |

| Audio Mixer                                                                    | Network Manager                                                                    |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| [<img width="320" src="./docs/floating_mixer.png">](./docs/floating_mixer.gif) | [<img width="320" src="./docs/floating_network.png">](./docs/floating_network.gif) |
| `pulsemixer`                                                                   | `nmtui`                                                                            |

## 🌐 Infrastructure

### 🚀 [Houston Server](./machines/houston/README.md)

My main public VPS running on [Hetzner Cloud](https://www.hetzner.com/cloud/)
(CX32: 4 vCPU, 8GB RAM, 80GB SSD).

**What it does:**

- **🔐 Authentication Hub**: Authelia + LLDAP for SSO across all services
- **📊 Full Observability Stack**: Grafana, VictoriaMetrics, InfluxDB, Telegraf,
  Vector
- **📱 Self-Hosted Apps**: DokuWiki, Linkding, Miniflux, Shaarli, and more

**[→ See complete service list and details](./machines/houston/README.md)**

### 💻 [Gagarin Workstation](./machines/gagarin/README.md)

My main desktop workstation for daily development and productivity.

**Setup:**

- **🪟 i3 Tiling WM**: Efficient workspace management with custom keybindings
- **🛠️ Full Dev Environment**: VIDE (Neovim), VS Code, Git, Docker, and more
- **🎨 Creative Tools**: GIMP, Inkscape, LibreOffice
- **⚙️ System Management**: TUI panels for quick access to system controls

**[→ See complete configuration and tools](./machines/gagarin/README.md)**

### All Hosts

Complete list of hosts in the homelab (auto-generated with `just doc-update`):

[comment]: (>>HOSTS)

<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>OS</th>
        <th>Description</th>
    </tr><tr>
            <td><a href="./docs/hosts/box.md"><img width="32" src="https://logos-marques.com/wp-content/uploads/2022/03/SFR-Logo-1994.png"></a></td>
            <td><a href="./docs/hosts/box.md">box</a>&nbsp;(192.168.0.1)</td>
            <td>Sagem</td>
            <td>SFR internet box</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-living.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-living.md">router-living</a>&nbsp;(192.168.254.254)</td>
            <td>MikroTik</td>
            <td>Livingroom mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-ladbedroom.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-ladbedroom.md">router-ladbedroom</a>&nbsp;(192.168.254.253)</td>
            <td>MikroTik</td>
            <td>Bedroom mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-homeoffice.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-homeoffice.md">router-homeoffice</a>&nbsp;(192.168.254.252)</td>
            <td>MikroTik</td>
            <td>Office mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/sadhome.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/sadhome.md">sadhome</a>&nbsp;(192.168.254.200)</td>
            <td>NixOS</td>
            <td>Stephanie's laptop</td>
        </tr><tr>
            <td><a href="./docs/hosts/rpi40.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/rpi40.md">rpi40</a>&nbsp;(192.168.254.101)</td>
            <td>NixOS</td>
            <td>The RPI 4 server</td>
        </tr><tr>
            <td><a href="./docs/hosts/bootstore.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/bootstore.md">bootstore</a>&nbsp;(192.168.254.100)</td>
            <td>NixOS</td>
            <td>HP Microserver N40L server</td>
        </tr><tr>
            <td><a href="./docs/hosts/b4d14.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/b4d14.md">b4d14</a>&nbsp;(192.168.254.124)</td>
            <td>NixOS</td>
            <td>Dell XPS 9560 Latop</td>
        </tr><tr>
            <td><a href="./docs/hosts/badxps.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/badxps.md">badxps</a>&nbsp;(192.168.254.114)</td>
            <td>NixOS</td>
            <td>Dell XPS 9570 Latop</td>
        </tr><tr>
            <td><a href="./docs/hosts/vm-test.md"><img width="32" src="https://cdn.icon-icons.com/icons2/2699/PNG/512/qemu_logo_icon_169821.png"></a></td>
            <td><a href="./docs/hosts/vm-test.md">vm-test</a>&nbsp;(127.0.0.1)</td>
            <td>NixOS</td>
            <td>qemu VM (SSH on port 2222)</td>
        </tr><tr>
            <td><a href="./docs/hosts/cab1e.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/cab1e.md">cab1e</a>&nbsp;(84.234.31.97)</td>
            <td>NixOS</td>
            <td>Wireguard VPN anonymizer server</td>
        </tr>
        <tr>
            <td><a href="./machines/houston/README.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./machines/houston/README.md">houston</a>&nbsp;(91.99.130.127)</td>
            <td>NixOS</td>
            <td>Main public server</td>
        </tr>
        <tr>
            <td><a href="./machines/gagarin//README.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./machines/gagarin/README.md">gagarin</a>&nbsp;(192.168.254.147)</td>
            <td>NixOS</td>
            <td>My main desktop workstation</td>
        </tr>
</table>

[comment]: (<<HOSTS)

### Network Topology

![Network diagram](./docs/network.png)

### Common Commands

![Available commands](docs/commands.png)

## ❤️ Thanks

A big thank to the contributors of OpenSource projects in particular :

- [clan project](https://clan.lol/) Simplest way to re-enter independent
  computing with our framework
- [doctor-cluster-config](https://github.com/TUM-DSE/doctor-cluster-config) from
  German TUM School of Computation
- [Mic92](https://github.com/Mic92/dotfiles) and for his some nix contributions
- [Misterio77](https://github.com/Misterio77/nix-config) and for his some nix
  contributions
- [longerHV](https://github.com/LongerHV/nixos-configuration) nix configuration
  file
- [wikipedia](https://www.wikipedia.org) for logos inventories

```
```
