# Host informations

This page generated with `inv docs.all-pages`


[comment]: (>>HOSTINFOS)


### Role

<table>
    <tr>
        <th>Logo</th>
        <th>Module</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr><tr>
            <td><img width="32" src="https://play-lh.googleusercontent.com/pCqOLS2w-QaTI63tjFLvncHnbXc4100EQI3FAD0RZEFWjGMa_54M4x2HD7j48qMSv3kk"></td>
            <td>adguard</td>
            <td>bootstore</td>
        <td>DNS ad blocker [service port 3002]</td>
        <tr>
            <td><a href="../acme.md"><img width="32" src="https://www.kevinsubileau.fr/wp-content/uploads/2016/03/letsencrypt-logo-pad.png"></a></td>
            <td><a href="../acme.md">acme</a></td>
            <td>bootstore</td>
        <td>Let's Encrypt Automatic Certificate Management Environment</td>
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
            <td><a href="../nix-serve.md"><img width="32" src="https://camo.githubusercontent.com/33a99d1ffcc8b23014fd5f6dd6bfad0f8923d44d61bdd2aad05f010ed8d14cb4/68747470733a2f2f6e69786f732e6f72672f6c6f676f2f6e69786f732d6c6f676f2d6f6e6c792d68697265732e706e67"></a></td>
            <td><a href="../nix-serve.md">nix-serve</a></td>
            <td>bootstore</td>
        <td>For caching the nix build results</td>
        <tr>
            <td><img width="32" src="https://freesvg.org/img/ftntp-client.png"></td>
            <td>ntp</td>
            <td>bootstore</td>
        <td>Network Time Protocol</td>
        <tr>
            <td><a href="../prometheus.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Prometheus_software_logo.svg/2066px-Prometheus_software_logo.svg.png"></a></td>
            <td><a href="../prometheus.md">prometheus</a></td>
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
            <td><a href="../home-assistant.md"><img width="32" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Home_Assistant_Logo.svg/32px-Home_Assistant_Logo.svg.png"></a></td>
            <td><a href="../home-assistant.md">home-assistant</a></td>
            <td>bootstore</td>
        <td>Open source home automation [service port 8123]</td>
        </table>

### Scan

| Port | Proto | Service | Product | Extra info |
| ------ | ------ | ------ |------ |------ |
|22|tcp|ssh|OpenSSH|protocol 2.0|
|80|tcp|http|nginx||
|443|tcp|http|nginx||
|3000|tcp|ppp|||
|5000|tcp|upnp|||
|8081|tcp|http|Node.js Express framework||
|8082|tcp|blackice-alerts|||
|8083|tcp|us-srv|||
|8084|tcp|http|Golang net/http server|Go-IPFS json-rpc or InfluxDB API|
|9100|tcp|jetdirect|||



### Config

```text
Arch     : x86_64
CPU      : 2 x AMD Turion(tm) II Neo N40L Dual-Core Processor
BogoMIPS : 2994
RAM      : 8 Go Go
DISK     : 3.64 TiB Go
KERNEL   : 5.15.86
```

### Topologie


![hardware topology](https://raw.githubusercontent.com/badele/nix-homelab/master/docs/hosts/bootstore/topologie.svg)


### Hardwares

```
System:    Kernel: 5.15.86 x86_64 bits: 64 compiler: gcc v: 11.3.0
           parameters: BOOT_IMAGE=(hd0,msdos1)//kernels/2dgaqj44642crwhnjyisgq93nqhf9xqh-linux-5.15.86-bzImage
           init=/nix/store/v4vrhjf417pxlvi81d0dwdj8ha4bzp5b-nixos-system-bootstore-23.05.20230105.a518c77/init
           nohibernate loglevel=4
           Console: N/A Distro: NixOS 23.05 (Stoat)
Machine:   Type: Desktop System: HP product: ProLiant MicroServer v: N/A serial: <filter> Chassis:
           type: 7 serial: N/A
           Mobo: N/A model: N/A serial: N/A BIOS: HP v: O41 date: 07/29/2011
Memory:    RAM: total: 7.65 GiB used: 6.03 GiB (78.8%)
           Array-1: capacity: 8 GiB slots: 2 EC: Single-bit ECC max-module-size: 4 GiB note: est.
           Device-1: DIMM0 size: 4 GiB speed: 1333 MT/s type: Other detail: synchronous
           bus-width: 64 bits total: 72 bits manufacturer: N/A part-no: N/A serial: N/A
           Device-2: DIMM1 size: 4 GiB speed: 1333 MT/s type: Other detail: synchronous
           bus-width: 64 bits total: 72 bits manufacturer: N/A part-no: N/A serial: N/A
PCI Slots: Slot: 1 type: x16 PCI Express PCIE1-J5 status: Available length: Short
           Slot: 2 type: x1 PCI Express PCIE2-J6 status: Available length: Short
CPU:       Info: Dual Core model: AMD Turion II Neo N40L bits: 64 type: MCP arch: K10
           family: 10 (16) model-id: 6 stepping: 3 microcode: 10000C8 cache: L1: 256 KiB L2: 2 MiB
           flags: lm nx pae sse sse2 sse3 sse4a svm bogomips: 5989
           Speed: 1500 MHz min/max: 800/1500 MHz base/boost: 1500/2200 volts: 1.1 V
           ext-clock: 200 MHz Core speeds (MHz): 1: 1500 2: 1500
           Vulnerabilities: Type: itlb_multihit status: Not affected
           Type: l1tf status: Not affected
           Type: mds status: Not affected
           Type: meltdown status: Not affected
           Type: mmio_stale_data status: Not affected
           Type: retbleed status: Not affected
           Type: spec_store_bypass status: Not affected
           Type: spectre_v1 mitigation: usercopy/swapgs barriers and __user pointer sanitization
           Type: spectre_v2
           mitigation: Retpolines, STIBP: disabled, RSB filling, PBRSB-eIBRS: Not affected
           Type: srbds status: Not affected
           Type: tsx_async_abort status: Not affected
Graphics:  Device-1: AMD RS880M [Mobility Radeon HD 4225/4250]
           vendor: Hewlett-Packard ProLiant MicroServer N36L driver: radeon v: kernel
           bus-ID: 01:05.0 chip-ID: 1002:9712 class-ID: 0300
           Display: server: No display server data found. Headless machine? tty: N/A
           Message: Advanced graphics data unavailable in console for root.
Audio:     Message: No device data found.
Network:   Device-1: Broadcom NetXtreme BCM5723 Gigabit Ethernet PCIe
           vendor: Hewlett-Packard NC107i Server driver: tg3 v: kernel port: e000 bus-ID: 02:00.0
           chip-ID: 14e4:165b class-ID: 0200
           IF: enp2s0 state: up speed: 1000 Mbps duplex: full mac: <filter>
           IP v4: <filter> scope: global
           IF-ID-1: docker0 state: up speed: 10000 Mbps duplex: unknown mac: <filter>
           IP v4: <filter> scope: global broadcast: <filter>
           IF-ID-2: veth2f8670e state: up speed: 10000 Mbps duplex: full mac: <filter>
           IF-ID-3: veth3e4c9b1 state: up speed: 10000 Mbps duplex: full mac: <filter>
           IF-ID-4: veth4420c24 state: up speed: 10000 Mbps duplex: full mac: <filter>
           WAN IP: <filter>
RAID:      Device-1: zroot type: zfs status: ONLINE level: mirror-0 size: 1.8 TiB free: 1.77 TiB
           allocated: 30.9 GiB
           Components: Online: N/A
Drives:    Local Storage: total: raw: 3.64 TiB usable: 5.44 TiB used: 31.02 GiB (0.6%)
           ID-1: /dev/sda maj-min: 8:0 vendor: Seagate model: ST2000DM001-1ER164
           family: Barracuda 7200.14 (AF) size: 1.82 TiB block-size: physical: 4096 B
           logical: 512 B sata: 3.1 speed: 3.0 Gb/s rotation: 7200 rpm serial: <filter> rev: CC25
           temp: 30 C scheme: MBR
           SMART: yes state: enabled health: PASSED on: 2y 254d 3h cycles: 56 read: 67.5 TiB
           written: 25.45 TiB Pre-Fail: attribute: Spin_Retry_Count value: 100 worst: 100
           threshold: 97
           ID-2: /dev/sdb maj-min: 8:16 vendor: Seagate model: ST2000DM008-2FR102
           family: BarraCuda 3.5 (SMR) size: 1.82 TiB block-size: physical: 4096 B logical: 512 B
           sata: 3.1 speed: 3.0 Gb/s rotation: 7200 rpm serial: <filter> rev: 0001 temp: 32 C
           scheme: MBR
           SMART: yes state: enabled health: PASSED on: 126d 12h cycles: 16 read: 272.8 GiB
           written: 6.13 TiB Pre-Fail: attribute: Spin_Retry_Count value: 100 worst: 100
           threshold: 97
Partition: ID-1: / raw-size: N/A size: 1.72 TiB used: 5.18 GiB (0.3%) fs: zfs
           logical: zroot/public/root
           ID-2: /boot raw-size: 1024 MiB size: 1022 MiB (99.80%) used: 127.7 MiB (12.5%) fs: vfat
           block-size: 512 B dev: /dev/sda1 maj-min: 8:1
Swap:      Kernel: swappiness: 60 (default) cache-pressure: 100 (default)
           ID-1: swap-1 type: partition size: 8 GiB used: 18.3 MiB (0.2%) priority: -2
           dev: /dev/sdb2 maj-min: 8:18
           ID-2: swap-2 type: partition size: 8 GiB used: 0 KiB (0.0%) priority: -3 dev: /dev/sda2
           maj-min: 8:2
Sensors:   System Temperatures: cpu: 47.2 C mobo: N/A
           Fan Speeds (RPM): N/A
Info:      Processes: 212
           Uptime: 08:30:36  up 45 days 13:23,  0 users,  load average: 1.17, 1.08, 1.00
           wakeups: 0 Init: systemd v: 253 target: multi-user.target tool: systemctl Compilers:
           gcc: 11.3.0 Packages: nix-default: 0 nix-sys: 637 lib: 144 nix-usr: 0 Client: Sudo
           v: 1.9.13p3 inxi: 3.3.04
```



[comment]: (<<HOSTINFOS)

## Install from scratch

Start [Commons installation](../installation.md)

On specific **host section**
```

##########################################################
# Nix serve binary cache
##########################################################

# configure nix-server, <One time> add host and public key to features/system/nix.nix
inv init-nix-serve --hosts ${TARGETIP} --hostnames ${TARGETNAME}
```

End [Commons installation](../installation.md) with **custom task**

TODO: update rpi40, bootstore nix-server documentation and remove persistent store
