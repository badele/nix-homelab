# nix-homelab

Practically all hosts from this home lab installed by Nix system. 

All the configuration is stored on `homelab.json`  file, you can do:
- Define network CIDR
- Define hosts
- Define the roles installed for selected hosts
- Define services descriptions

Also, from the `homelab.json` you can do:
- Generate documentation automatically
- Install automatically roles

## Hosts

List of hosts composing the home lab

This list generated with `inv docs.all-pages` command

[comment]: (>>HOSTS)

<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>Arch</th>
        <th>OS</th>
        <th>CPU</th>
        <th>Memory</th>
        <th>Disk</th>
        <th>Description</th>
    </tr><tr>
            <td><a href="./docs/hosts/box.md"><img width="32" src="https://logos-marques.com/wp-content/uploads/2022/03/SFR-Logo-1994.png"></a></td>
            <td><a href="./docs/hosts/box.md">box</a>&nbsp;(192.168.0.1)</td>
            <td></td>
            <td>Sagem</td>
            <td></td>
            <td></td>
            <td></td>
            <td>SFR internet box</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-living.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-living.md">router-living</a>&nbsp;(192.168.254.254)</td>
            <td></td>
            <td>MikroTik</td>
            <td></td>
            <td></td>
            <td></td>
            <td>External home mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-bedroom.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-bedroom.md">router-bedroom</a>&nbsp;(192.168.254.253)</td>
            <td></td>
            <td>MikroTik</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Bedroom home mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/router-homeoffice.md"><img width="32" src="https://cdn.shopify.com/s/files/1/0653/8759/3953/files/512.png?v=1657867177&width=32"></a></td>
            <td><a href="./docs/hosts/router-homeoffice.md">router-homeoffice</a>&nbsp;(192.168.254.252)</td>
            <td></td>
            <td>MikroTik</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Office home mikrotik router</td>
        </tr><tr>
            <td><a href="./docs/hosts/sam.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Xfce_logo-footprint.svg/32px-Xfce_logo-footprint.svg.png"></a></td>
            <td><a href="./docs/hosts/sam.md">sam</a>&nbsp;(192.168.0.18)</td>
            <td></td>
            <td>NixOS</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Samsung N110 Latop</td>
        </tr><tr>
            <td><a href="./docs/hosts/latino.md"><img width="32" src="https://styles.redditmedia.com/t5_6sciw0/styles/communityIcon_h3cvittvupi91.png"></a></td>
            <td><a href="./docs/hosts/latino.md">latino</a>&nbsp;(192.168.254.152)</td>
            <td>4</td>
            <td>NixOS</td>
            <td></td>
            <td>8 Go</td>
            <td>465.76 GiB</td>
            <td>Dell Latitude E5540 Latop</td>
        </tr><tr>
            <td><a href="./docs/hosts/rpi40.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/fr/thumb/3/3b/Raspberry_Pi_logo.svg/32px-Raspberry_Pi_logo.svg.png"></a></td>
            <td><a href="./docs/hosts/rpi40.md">rpi40</a>&nbsp;(192.168.254.101)</td>
            <td>4</td>
            <td>NixOS</td>
            <td></td>
            <td>8 Go</td>
            <td>495.48 GiB</td>
            <td>The Raspberry PI 4 storage server</td>
        </tr><tr>
            <td><a href="./docs/hosts/bootstore.md"><img width="32" src="https://simpleicons.org/icons/databricks.svg"></a></td>
            <td><a href="./docs/hosts/bootstore.md">bootstore</a>&nbsp;(192.168.254.100)</td>
            <td>2</td>
            <td>NixOS</td>
            <td></td>
            <td>8 Go</td>
            <td>3.64 TiB</td>
            <td>HP Proliant Microserver N40L storage server</td>
        </tr><tr>
            <td><a href="./docs/hosts/badwork.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/IBM_ThinkPad_logo_askew_badge.svg/32px-IBM_ThinkPad_logo_askew_badge.svg.png"></a></td>
            <td><a href="./docs/hosts/badwork.md">badwork</a>&nbsp;(192.168.254.177)</td>
            <td>12</td>
            <td>Nix</td>
            <td></td>
            <td>32 Go</td>
            <td>953.87 GiB</td>
            <td>A work thinkpad</td>
        </tr><tr>
            <td><a href="./docs/hosts/badphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/badphone.md">badphone</a>&nbsp;(192.168.254.120)</td>
            <td></td>
            <td>Android</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Bruno's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/ladphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/ladphone.md">ladphone</a>&nbsp;(192.168.254.106)</td>
            <td></td>
            <td>Android</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Lucas's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/sadphone.md"><img width="32" src="https://cdn-icons-png.flaticon.com/512/38/38002.png"></a></td>
            <td><a href="./docs/hosts/sadphone.md">sadphone</a>&nbsp;(192.168.254.110)</td>
            <td></td>
            <td>Android</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Steph's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/loadphone.md"><img width="32" src="https://img.freepik.com/icones-gratuites/pomme_318-162866.jpg"></a></td>
            <td><a href="./docs/hosts/loadphone.md">loadphone</a>&nbsp;(192.168.254.111)</td>
            <td></td>
            <td>Iphone</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Lou's phone</td>
        </tr><tr>
            <td><a href="./docs/hosts/tv-chromecast.md"><img width="32" src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQrW-wZZhmKpadJqRe73njFwEDLzh-jIn1XaSbCVhgMmoN46pgj6M4Fq1tWyr5w_z_HcP4&usqp=CAU"></a></td>
            <td><a href="./docs/hosts/tv-chromecast.md">tv-chromecast</a>&nbsp;(192.168.254.105)</td>
            <td></td>
            <td>Chromecast</td>
            <td></td>
            <td></td>
            <td></td>
            <td>TV Chromecast</td>
        </tr><tr>
            <td><a href="./docs/hosts/bedroom-googlemini-A.md"><img width="32" src="https://c.clc2l.com/t/g/o/google-home-wxDa7w.png"></a></td>
            <td><a href="./docs/hosts/bedroom-googlemini-A.md">bedroom-googlemini-A</a>&nbsp;(192.168.254.191)</td>
            <td></td>
            <td>GoogleMini</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Google Mini room A</td>
        </tr><tr>
            <td><a href="./docs/hosts/bedroom-googlemini-C.md"><img width="32" src="https://c.clc2l.com/t/g/o/google-home-wxDa7w.png"></a></td>
            <td><a href="./docs/hosts/bedroom-googlemini-C.md">bedroom-googlemini-C</a>&nbsp;(192.168.254.193)</td>
            <td></td>
            <td>GoogleMini</td>
            <td></td>
            <td></td>
            <td></td>
            <td>Google Mini room C</td>
        </tr></table>

[comment]: (<<HOSTS)


## Roles

The main roles used in this home lab

This list generated with `inv docs.all-pages` command

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
        <td>router-living, badphone</td>
        <td>An VPN client/server alternative to IPSec and OpenVPN</td>
        <tr>
        <td><a href="./docs/coredns.md"><img width="32" src="https://raw.githubusercontent.com/coredns/logo/master/Icon/CoreDNS_Colour_Icon.png"></a></td>
        <td><a href="./docs/coredns.md">coredns</a></td>
        <td>rpi40, bootstore</td>
        <td>A Go DNS server, it used for serving local hosts and alias</td>
        <tr>
        <td><a href="./docs/ntp.md"><img width="32" src="https://freesvg.org/img/ftntp-client.png"></a></td>
        <td><a href="./docs/ntp.md">ntp</a></td>
        <td>rpi40, bootstore</td>
        <td>Network Time Protocol</td>
        <tr>
        <td><a href="./docs/dashy.md"><img width="32" src="https://dashy.to/img/dashy.png"></a></td>
        <td><a href="./docs/dashy.md">dashy</a></td>
        <td>bootstore</td>
        <td>The Ultimate Homepage for your Homelab [service port 8081]</td>
        <tr>
        <td><a href="./docs/grafana.md"><img width="32" src="https://patch.pulseway.com/Images/features/patch/3pp-logos/Grafana.png"></a></td>
        <td><a href="./docs/grafana.md">grafana</a></td>
        <td>bootstore</td>
        <td>The open and composable observability and data visualization platform [service port 3000]</td>
        <tr>
        <td><a href="./docs/loki.md"><img width="32" src="https://grafana.com/static/img/logos/logo-loki.svg"></a></td>
        <td><a href="./docs/loki.md">loki</a></td>
        <td>bootstore</td>
        <td>Scalable log aggregation system [service port 8084,9095]</td>
        <tr>
        <td><a href="./docs/nfs.md"><img width="32" src="https://logo-marque.com/wp-content/uploads/2021/09/Need-For-Speed-Logo-2019-2020.jpg"></a></td>
        <td><a href="./docs/nfs.md">nfs</a></td>
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
        <td><a href="./docs/smokeping.md"><img width="32" src="https://img.freepik.com/vecteurs-premium/cardiogramme-cardiaque-isole-blanc_97886-1185.jpg?w=2000"></a></td>
        <td><a href="./docs/smokeping.md">smokeping</a></td>
        <td>bootstore</td>
        <td>Latency measurement tool</td>
        <tr>
        <td><a href="./docs/statping.md"><img width="32" src="https://avatars.githubusercontent.com/u/61949049?s=32&v=4"></a></td>
        <td><a href="./docs/statping.md">statping</a></td>
        <td>bootstore</td>
        <td>A Status Page for monitoring your websites and applications with beautiful graphs [service port 8082]</td>
        <tr>
        <td><a href="./docs/uptime.md"><img width="32" src="https://cf.appdrag.com/dashboard-openvm-clo-b2d42c/uploads/Uptime-kuma-7fPG.png"></a></td>
        <td><a href="./docs/uptime.md">uptime</a></td>
        <td>bootstore</td>
        <td>A Status Page [service port 8083]</td>
        </table>

[comment]: (<<ROLES)

## Homelab initialisation
```
inv init.domain-cert
```

## Commons scratch installation

Boot from NixOS live cd

```
##########################################################
# NixOS installation configuration
##########################################################

# Change keymap & root password
sudo -i
loadkeys fr
passwd 

# From other computer, enter to deploy environment
# NOTE: Use <SPACE> before command for not storing command in bash history (for secure your passwords)
nix develop
export TARGETIP=<hostip>
export TARGETNAME=<hostname>

ssh-copy-id root@${TARGETIP}
 inv disk-format --hosts ${TARGETIP} --disk /dev/sda --mirror /dev/sdb --mode MBR
 [Optional] inv disk-mount --hosts ${TARGETIP} --mirror true --password "<zfspassword>"
inv ssh-init-host-key --hosts ${TARGETIP} --hostnames ${TARGETNAME}
inv nixos-generate-config --hosts ${TARGETIP} --hostnames ${TARGETNAME} --name hp-proliant-microserver-n40l

# Add hosts/bootstore/ssh-to-age.txt content to .sops.yaml
# Add root password key to ./hosts/bootstore/secrets.yml 
echo 'yourpassword' | mkpasswd -m sha-512 -s

# Re-encrypt all keys for the previous host
sops updatekeys ./hosts/${TARGETNAME}/secrets.yml

####################################################
# Execute your custom task here, exemple:
# - Restore persist borgbackup
# - Configure some program (private key generation)
####################################################

# Add hostname in configurations.nix with minimalModules
# Configure hosts/<hostname>/default.nix

# NixOS installation
inv nixos-install --hosts ${TARGETIP} --flakeattr ${TARGETNAME}
```

## Update nixos

```
inv deploy --hosts bootstore
```


## Commands

Home lab commands list

This list generated with `inv docs.all-pages` command

[comment]: (>>COMMANDS)

```
Available tasks:

  docs.all-pages     generate all homelab documentation
  docs.host-pages    generate all homelab hosts page
  docs.main-page     generate main homelab page
  init.domain-cert   Init domain certificate
  init.nix-serve     Init nix binary cache server <hostname> nix-serve private
                     & public key
  nix.build          Build for <hostnames>
  nix.deploy         Deploy to <hostnames> server
  role.build         Build for all hosts contains the role
  role.deploy        Deploy for all hosts contains the role
  wireguard.keys     Generate wireguard private key for <hostname>


```


[comment]: (<<COMMANDS)


# A big thanks ❤️

A big thank to the contributors of OpenSource projects in particular :
- [doctor-cluster-config](https://github.com/TUM-DSE/doctor-cluster-config) from German TUM School of Computation
- [Mic92](https://github.com/Mic92/dotfiles) and for his some nix contributions
- [Misterio77](https://github.com/Misterio77/nix-config) and for his some nix contributions
- [longerHV](https://github.com/LongerHV/nixos-configuration) nix configuration file