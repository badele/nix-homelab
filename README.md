# nix-homelab

<!--toc:start-->

- [nix-homelab](#nix-homelab)
  - [Features](#features)
    - [Roles](#roles)
    - [User programs](#user-programs)
    - [TUI floating panel configuration](#tui-floating-panel-configuration)
  - [Documentation](#documentation)
    - [Hosts](#hosts)
    - [Network](#network)
    - [Structure](#structure)
  - [Usage](#usage)
    - [Demo](#demo)
      - [Installation](#installation)
      - [Update](#update)
      - [Re-use the demo](#re-use-the-demo)
    - [Secrets initialisation (AGE & SOPS)](#secrets-initialisation-age-sops)
    - [Homelab initialisation](#homelab-initialisation)
    - [NixOS installation & update](#nixos-installation-update)
      - [Update from you local computer/laptop](#update-from-you-local-computerlaptop)
    - [Update roles or multiple hosts](#update-roles-or-multiple-hosts)
  - [Commands](#commands)
- [A big thanks ❤️](#a-big-thanks-️)

<!--toc:end-->

## Features

This homelab entirelly managed by [NixOS](https://nixos.org/)

All the configuration is stored on `homelab.json` file, you can do:

- Define network CIDR
- Define hosts
- Define the roles installed for selected hosts
- Define services descriptions
- etc ...

This documentation is generated from `homelab.json` file content

<img width="100%" src="./docs/nixos.gif" />

### Roles

The main roles used in this home lab

This list generated with `just doc-update` command

[comment]: (>>ROLES)

<table>
    <tr>
        <th>Logo</th>
        <th>Module</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr><tr>
            <td><a href="./docs/wireguard.md"><img width="32" src="https://cdn.icon-icons.com/icons2/2699/PNG/512/wireguard_logo_icon_168760.png"></a></td>
            <td><a href="./docs/wireguard.md">wireguard</a></td>
            <td>router-living, badphone, cab1e</td>
        <td>An VPN client/server alternative to IPSec and OpenVPN</td>
        <tr>
            <td><a href="./docs/acme.md"><img width="32" src="https://www.kevinsubileau.fr/wp-content/uploads/2016/03/letsencrypt-logo-pad.png"></a></td>
            <td><a href="./docs/acme.md">acme</a></td>
            <td>rpi40, bootstore</td>
        <td>Let's Encrypt Automatic Certificate Management Environment</td>
        <tr>
            <td><img width="32" src="https://raw.githubusercontent.com/coredns/logo/master/Icon/CoreDNS_Colour_Icon.png"></td>
            <td>coredns</td>
            <td>rpi40</td>
        <td>A Go DNS server, it used for serving local hosts and alias</td>
        <tr>
            <td><img width="32" src="https://freesvg.org/img/ftntp-client.png"></td>
            <td>ntp</td>
            <td>rpi40, bootstore, srvhoma</td>
        <td>Network Time Protocol</td>
        <tr>
            <td><img width="32" src="https://developer.community.boschrexroth.com/t5/image/serverpage/image-id/13467i19FDFA6E5DC7C260?v=v2"></td>
            <td>mosquitto</td>
            <td>rpi40</td>
        <td>A mqtt broker [service port 1883]</td>
        <tr>
            <td><a href="./docs/zigbee2mqtt.md"><img width="32" src="https://www.zigbee2mqtt.io/logo.png"></a></td>
            <td><a href="./docs/zigbee2mqtt.md">zigbee2mqtt</a></td>
            <td>rpi40</td>
        <td>A zigbee2mqtt [service port 8080]</td>
        <tr>
            <td><img width="32" src="https://play-lh.googleusercontent.com/pCqOLS2w-QaTI63tjFLvncHnbXc4100EQI3FAD0RZEFWjGMa_54M4x2HD7j48qMSv3kk"></td>
            <td>adguard</td>
            <td>bootstore</td>
        <td>DNS ad blocker [service port 3002]</td>
        <tr>
            <td><img width="32" src="https://dashy.to/img/dashy.png"></td>
            <td>dashy</td>
            <td>bootstore</td>
        <td>The Ultimate Homepage for your Homelab [service port 8081]</td>
        <tr>
            <td><img width="32" src="https://patch.pulseway.com/Images/features/patch/3pp-logos/Grafana.png"></td>
            <td>grafana</td>
            <td>bootstore</td>
        <td>The open and composable observability and data visualization platform [service port 3000]</td>
        <tr>
            <td><img width="32" src="https://grafana.com/static/img/logos/logo-loki.svg"></td>
            <td>loki</td>
            <td>bootstore</td>
        <td>Scalable log aggregation system [service port 8084,9095]</td>
        <tr>
            <td><img width="32" src="https://logo-marque.com/wp-content/uploads/2021/09/Need-For-Speed-Logo-2019-2020.jpg"></td>
            <td>nfs</td>
            <td>bootstore</td>
        <td>A Linux NFS server, it used for backuping a servers and Latops</td>
        <tr>
            <td><a href="./docs/nix-serve.md"><img width="32" src="https://camo.githubusercontent.com/33a99d1ffcc8b23014fd5f6dd6bfad0f8923d44d61bdd2aad05f010ed8d14cb4/68747470733a2f2f6e69786f732e6f72672f6c6f676f2f6e69786f732d6c6f676f2d6f6e6c792d68697265732e706e67"></a></td>
            <td><a href="./docs/nix-serve.md">nix-serve</a></td>
            <td>bootstore</td>
        <td>For caching the nix build results</td>
        <tr>
            <td><a href="./docs/prometheus.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Prometheus_software_logo.svg/2066px-Prometheus_software_logo.svg.png"></a></td>
            <td><a href="./docs/prometheus.md">prometheus</a></td>
            <td>bootstore</td>
        <td>Monitoring system and time series database [service port 9090]</td>
        <tr>
            <td><img width="32" src="https://img.freepik.com/vecteurs-premium/cardiogramme-cardiaque-isole-blanc_97886-1185.jpg?w=2000"></td>
            <td>smokeping</td>
            <td>bootstore</td>
        <td>Latency measurement tool</td>
        <tr>
            <td><img width="32" src="https://avatars.githubusercontent.com/u/61949049?s=32&v=4"></td>
            <td>statping</td>
            <td>bootstore</td>
        <td>A Status Page for monitoring your websites and applications with beautiful graphs [service port 8082]</td>
        <tr>
            <td><img width="32" src="https://cf.appdrag.com/dashboard-openvm-clo-b2d42c/uploads/Uptime-kuma-7fPG.png"></td>
            <td>uptime</td>
            <td>bootstore</td>
        <td>A Status Page [service port 3001/8083]</td>
        <tr>
            <td><a href="./docs/home-assistant.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Home_Assistant_Logo.svg/32px-Home_Assistant_Logo.svg.png"></a></td>
            <td><a href="./docs/home-assistant.md">home-assistant</a></td>
            <td>bootstore</td>
        <td>Open source home automation [service port 8123]</td>
        </table>

[comment]: (<<ROLES)

### User programs

| Logo                                                                                                                                                                                      | Name        | Description                                                                                               |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| [<img width="32" src="https://aider.chat/assets/icons/favicon-32x32.png">](./users/badele/commons.nix)                                                                                    | Aider       | [AI Pair programming](./users/badele/commons.nix)                                                         |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Firefox_logo%2C_2019.svg/32px-Firefox_logo%2C_2019.svg.png">](./users/badele/firefox.nix)                 | Firefox     | [Browser](./users/badele/firefox.nix)                                                                     |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/The_GIMP_icon_-_gnome.svg/32px-The_GIMP_icon_-_gnome.svg.png">](./users/badele/commons.nix)               | Gimp        | [Raster graphics editor](./users/badele/commons.nix)                                                      |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/I3_window_manager_logo.svg/32px-I3_window_manager_logo.svg.png">](./users/badele/commons.nix)             | i3          | [Tiling window manager](./nix/home-manager/features/desktop/xorg/wm/i3.nix)                               |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Inkscape_Logo.svg/32px-Inkscape_Logo.svg.png">](./users/badele/commons.nix)                               | Inkscape    | [Vectorial graphics editor](./users/badele/commons.nix)                                                   |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/LibreOffice_icon_3.3.1_48_px.svg/32px-LibreOffice_icon_3.3.1_48_px.svg.png">](./users/badele/commons.nix) | Libreoffice | [Office editor](./users/badele/commons.nix)                                                               |
| [<img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Meld_Logo.svg/128px-Meld_Logo.svg.png">](./users/badele/commons.nix)                                      | Meld        | [Awesome diff tool](./users/badele/commons.nix)                                                           |
| [<img width="32" src="https://raw.githubusercontent.com/denisidoro/navi/master/assets/icon.png">](./nix/home-manager/features/term/base.nix)                                              | Navi        | [interactive cheatsheet tool](https://github.com/badele/vide)                                             |
| [<img width="32" src="https://user-images.githubusercontent.com/28633984/66519056-2e840c80-eaef-11e9-8670-c767213c26ba.png">](https://github.com/badele/vide)                             | Neovim      | [doc](/docs/nvim/README.md) \| [**VIDE** (badele's customized nix neovim](https://github.com/badele/vide) |

### TUI floating panel configuration

| [<img width="320" src="./docs/floating_bluetooth.png">](./docs/floating_bluetooth.png) | [<img width="320" src="./docs/floating_disk.png">](./docs/floating_disk.png)       |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Bluetooth](./docs/floating_bluetooth.gif) (`bluetuith`)                               | [Disk](./docs/floating_disk.gif) (`bashmount`)                                     |
| [<img width="320" src="./docs/floating_mixer.png">](./docs/floating_mixer.png)         | [<img width="320" src="./docs/floating_network.png">](./docs/floating_network.png) |
| [Mixer](./docs/floating_mixer.gif) (`pulsemixer`)                                      | [Network](./docs/floating_network.gif) (`nmtui`)                                   |
| [<img width="320" src="./docs/floating_process.png">](./docs/floating_process.png)     |                                                                                    |
| [Process](./docs/floating_process.gif) (`pulsemixer`)                                  |                                                                                    |

## Documentation

### Hosts

List of hosts composing the home lab

This list generated with `just doc-update` command

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
            <td><a href="./docs/hosts/badphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/badphone.md">badphone</a>&nbsp;(192.168.254.194)</td>
            <td>Android</td>
            <td>Bruno's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/ladphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/ladphone.md">ladphone</a>&nbsp;(192.168.254.184)</td>
            <td>Android</td>
            <td>Lucas's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/sadphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/sadphone.md">sadphone</a>&nbsp;(192.168.254.188)</td>
            <td>Android</td>
            <td>Steph's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/loadphone.md"><img width="32" src="https://img.freepik.com/icones-gratuites/pomme_318-162866.jpg"></a></td>
            <td><a href="./docs/hosts/loadphone.md">loadphone</a>&nbsp;(192.168.254.199)</td>
            <td>Iphone</td>
            <td>Lou's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/tv-chromecast.md"><img width="32" src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQrW-wZZhmKpadJqRe73njFwEDLzh-jIn1XaSbCVhgMmoN46pgj6M4Fq1tWyr5w_z_HcP4&usqp=CAU"></a></td>
            <td><a href="./docs/hosts/tv-chromecast.md">tv-chromecast</a>&nbsp;(192.168.254.105)</td>
            <td>Chromecast</td>
            <td>TV Chromecast</td>
        </tr><tr>
            <td><a href="./docs/hosts/bedroom-googlemini-A.md"><img width="32" src="https://c.clc2l.com/t/g/o/google-home-wxDa7w.png"></a></td>
            <td><a href="./docs/hosts/bedroom-googlemini-A.md">bedroom-googlemini-A</a>&nbsp;(192.168.254.197)</td>
            <td>GoogleMini</td>
            <td>Google Mini room A</td>
        </tr><tr>
            <td><a href="./docs/hosts/bedroom-googlemini-C.md"><img width="32" src="https://c.clc2l.com/t/g/o/google-home-wxDa7w.png"></a></td>
            <td><a href="./docs/hosts/bedroom-googlemini-C.md">bedroom-googlemini-C</a>&nbsp;(192.168.254.196)</td>
            <td>GoogleMini</td>
            <td>Google Mini room C</td>
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
            <td><a href="./docs/hosts/badxps-eth.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/badxps-eth.md">badxps-eth</a>&nbsp;(192.168.254.179)</td>
            <td>NixOS</td>
            <td>Dell XPS 9570 Latop</td>
        </tr><tr>
            <td><a href="./docs/hosts/bridge-hue.md"><img width="32" src="https://www.daskeyboard.com/images/applets/philips-hue/icon.png"></a></td>
            <td><a href="./docs/hosts/bridge-hue.md">bridge-hue</a>&nbsp;(192.168.254.191)</td>
            <td>Bridge</td>
            <td>Philips Hue bridge</td>
        </tr><tr>
            <td><a href="./docs/hosts/srvhoma.md"><img width="32" src="https://nixos.wiki/images/thumb/2/20/Home-nixos-logo.png/207px-Home-nixos-logo.png"></a></td>
            <td><a href="./docs/hosts/srvhoma.md">srvhoma</a>&nbsp;(192.168.254.116)</td>
            <td>NixOS</td>
            <td>First NUC homelab server</td>
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
        </tr></table>

[comment]: (<<HOSTS)

### Network

|                                                          |
| :------------------------------------------------------: |
|  generated by `diagrams ./docs/network_architecture.py`  |
| ![Network architecture](./docs/network_architecture.png) |
|                                                          |
|       generated by `plantuml ./docs/network.puml`        |
|          ![Network diagram](./docs/network.png)          |

### Structure

- **Configuration**
  - `homelab.json`: main homelab file configuration (roles servers, network,
    etc)
  - `hosts`: hosts configuration (system, hardware, host secrets)
    - `*.nix`: user accounts
  - `users`: users configuration (on user environment, user secrets)
- **System**
  - `nix`: all ***.nix** files
    - `home-manager`: All users ***.nix** files (installed on user environment)
    - `modules`: all nix modules
      - `home-manager`: user modules
      - `nixos`: nixos modules (installed on system wide)
        - `host.nix`: host options (custom options for host)
    - `nixos`: all ***.nix** files installed on system wide
    - `overlays`: overlays **nix derivations**
    - `pkgs`: custom nix packages

## Usage

### Demo

To test `nix-homelab` as well as the configuration of a workstation,
`nix-homelab` offers a demo that runs on a virtual machine based on QEMU.

![usb-installer](./docs/usb-installer.png)

#### Installation

- From your desktop
  - `nix develop`
  - `just iso-build`
  - `just demo-qemu-nixos-install` (`demopass` password) Go for a walk or have a
    coffee
  - when the installation is completed, reboot the virtual machine (you can
    write `reboot` on the terminal) and select
    `Firmware Setup => Boot Manager => UEFI QEMU HardDisk`

![reboot](docs/reboot.png)

#### Update

You can update from your remote desktop or directly from your recent installed
desktop

- From remote
  - `just demo-qemu-nixos-update`

- From your fresh installation
  - `ssh root@localhost -p 2222` (`demopass` password)
  - `ghq clone https://github.com/badele/nix-homelab.git`
  - `cd ghq/github.com/badele/nix-homelab`
  - `just nixos-update`

#### Re-use the demo

```bash
just demo-start
```

### Secrets initialisation (AGE & SOPS)

Your `pass` (passwordstore) configuration must be correctly configured.

In order to be able to encrypt your credentials, you first need initialize an
`age` key. It is this key that will subsequently have to be added in the
`.sops.yaml` file

- `age-keygen | pass insert -m nix-homelab/users/your_username`
- `pass show nix-homelab/users/your_username | grep AGE-SECRET-KEY >> ~/.config/sops/age/keys.txt`

```
### NixOS installation & update

See [Commons installation](docs//installation.md)

#### Update from you local computer/laptop

- From your fresh installation
  - `ghq clone https://github.com/badele/nix-homelab.git`
  - `cd ghq/github.com/badele/nix-homelab`
  - `just nixos-update`
```

## Commands

Home lab commands list

This list generated with `just doc-update` command

![commands list](docs/commands.png)

# A big thanks ❤️

A big thank to the contributors of OpenSource projects in particular :

- [doctor-cluster-config](https://github.com/TUM-DSE/doctor-cluster-config) from
  German TUM School of Computation
- [Mic92](https://github.com/Mic92/dotfiles) and for his some nix contributions
- [Misterio77](https://github.com/Misterio77/nix-config) and for his some nix
  contributions
- [longerHV](https://github.com/LongerHV/nixos-configuration) nix configuration
  file
- [wikipedia](https://www.wikipedia.org) for logos inventories
