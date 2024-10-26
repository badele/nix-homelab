# RPI40

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
            <td><a href="../acme.md"><img width="32" src="https://www.kevinsubileau.fr/wp-content/uploads/2016/03/letsencrypt-logo-pad.png"></a></td>
            <td><a href="../acme.md">acme</a></td>
            <td>rpi40</td>
        <td>Let's Encrypt Automatic Certificate Management Environment</td>
        <tr>
            <td><img width="32" src="https://raw.githubusercontent.com/coredns/logo/master/Icon/CoreDNS_Colour_Icon.png"></td>
            <td>coredns</td>
            <td>rpi40</td>
        <td>A Go DNS server, it used for serving local hosts and alias</td>
        <tr>
            <td><img width="32" src="https://freesvg.org/img/ftntp-client.png"></td>
            <td>ntp</td>
            <td>rpi40</td>
        <td>Network Time Protocol</td>
        <tr>
            <td><img width="32" src="https://developer.community.boschrexroth.com/t5/image/serverpage/image-id/13467i19FDFA6E5DC7C260?v=v2"></td>
            <td>mosquitto</td>
            <td>rpi40</td>
        <td>A mqtt broker [service port 1883]</td>
        <tr>
            <td><a href="../zigbee2mqtt.md"><img width="32" src="https://www.zigbee2mqtt.io/logo.png"></a></td>
            <td><a href="../zigbee2mqtt.md">zigbee2mqtt</a></td>
            <td>rpi40</td>
        <td>A zigbee2mqtt [service port 8080]</td>
        </table>

### Scan

| Port | Proto | Service | Product | Extra info |
| ------ | ------ | ------ |------ |------ |
|22|tcp|ssh|OpenSSH|protocol 2.0|
|53|tcp|domain|Unbound||
|80|tcp|http|nginx||
|443|tcp|http|nginx||
|9100|tcp|jetdirect|||



### Config

```text
Arch     : aarch64
CPU      : 4 x Cortex-A72
BogoMIPS : 108
RAM      : 8 Go Go
DISK     : 495.48 GiB Go
KERNEL   : 5.15.74
```

### Topologie


![hardware topology](https://raw.githubusercontent.com/badele/nix-homelab/master/docs/hosts/rpi40/topologie.svg)


### Hardwares

```
System:    Kernel: 5.15.74 aarch64 bits: 64 compiler: gcc v: 9.5.0
           parameters: coherent_pool=1M 8250.nr_uarts=1 snd_bcm2835.enable_compat_alsa=0
           snd_bcm2835.enable_hdmi=1 bcm2708_fb.fbwidth=1184 bcm2708_fb.fbheight=624
           bcm2708_fb.fbswap=1 smsc95xx.macaddr=DC:A6:32:F0:05:16 vc_mem.mem_base=0x3eb00000
           vc_mem.mem_size=0x3ff00000 nohibernate loglevel=4
           init=/nix/store/l51q8xrjh5npkssi98xdg8fmxg3q0m25-nixos-system-rpi40-22.11.20230320.e2c9779/init
           Console: N/A Distro: NixOS 23.05 (Stoat)
Machine:   Type: ARM Device System: Raspberry Pi 4 Model B Rev 1.4 details: BCM2835 rev: d03114
           serial: <filter>
Memory:    RAM: total: 7.62 GiB used: 5.87 GiB (77.1%)
           RAM Report: smbios: No SMBIOS data for dmidecode to process
PCI Slots: ARM: No ARM data found for this feature.
CPU:       Info: Quad Core model: N/A variant: cortex-a72 bits: 64 type: MCP arch: ARMv8 family: 8
           model-id: 0 stepping: 3
           features: Use -f option to see features bogomips: 432
           Speed: 1400 MHz min/max: 600/1500 MHz Core speeds (MHz): 1: 1400 2: 1400 3: 1400
           4: 1400
           Vulnerabilities: Type: itlb_multihit status: Not affected
           Type: l1tf status: Not affected
           Type: mds status: Not affected
           Type: meltdown status: Not affected
           Type: mmio_stale_data status: Not affected
           Type: retbleed status: Not affected
           Type: spec_store_bypass status: Vulnerable
           Type: spectre_v1 mitigation: __user pointer sanitization
           Type: spectre_v2 status: Vulnerable
           Type: srbds status: Not affected
           Type: tsx_async_abort status: Not affected
Graphics:  Device-1: bcm2708-fb driver: bcm2708_fb v: kernel bus-ID: N/A chip-ID: brcm:soc
           class-ID: fb
           Device-2: bcm2711-hdmi0 driver: N/A bus-ID: N/A chip-ID: brcm:soc class-ID: hdmi
           Device-3: bcm2711-hdmi1 driver: N/A bus-ID: N/A chip-ID: brcm:soc class-ID: hdmi
           Display: server: No display server data found. Headless machine? tty: N/A
           Message: Advanced graphics data unavailable in console for root.
Audio:     Device-1: bcm2711-hdmi0 driver: N/A bus-ID: N/A chip-ID: brcm:soc class-ID: hdmi
           Device-2: bcm2711-hdmi1 driver: N/A bus-ID: N/A chip-ID: brcm:soc class-ID: hdmi
Network:   Device-1: bcm2835-mmc driver: mmc_bcm2835 v: N/A port: N/A bus-ID: N/A
           chip-ID: brcm:fe300000 class-ID: mmcnr
           IF: wlan0 state: down mac: <filter>
           Device-2: bcm2711-genet-v5 driver: bcmgenet v: N/A port: N/A bus-ID: N/A
           chip-ID: brcm:fd580000 class-ID: ethernet
           IF: eth0 state: up speed: 1000 Mbps duplex: full mac: <filter>
           IP v4: <filter> type: dynamic noprefixroute scope: global broadcast: <filter>
           IP v6: <filter> type: noprefixroute scope: link
           IF-ID-1: docker0 state: down mac: <filter>
           IP v4: <filter> scope: global broadcast: <filter>
           WAN IP: <filter>
RAID:      Device-1: zroot type: zfs status: ONLINE level: linear size: 464 GiB free: 444 GiB
           allocated: 20.3 GiB
           Components: Online: N/A
Drives:    Local Storage: total: raw: 495.48 GiB usable: 959.48 GiB used: 17.79 GiB (1.9%)
           ID-1: /dev/mmcblk0 maj-min: 179:0 vendor: SanDisk model: SL32G size: 29.72 GiB
           block-size: physical: 512 B logical: 512 B rotation: SSD serial: <filter> scheme: MBR
           SMART Message: Unknown smartctl error. Unable to generate data.
           ID-2: /dev/sda maj-min: 8:0 type: USB vendor: Hitachi model: HTS547550A9E384
           family: HGST Travelstar 5K750 size: 465.76 GiB block-size: physical: 4096 B
           logical: 512 B sata: 2.6 speed: 3.0 Gb/s rotation: 5400 rpm serial: <filter> rev: JE3O
           temp: 29 C scheme: GPT
           SMART: yes state: enabled health: PASSED on: 1y 233d 8h cycles: 69600 Old-Age:
           g-sense error rate: 1057 Pre-Fail: reallocated sector: 100 threshold: 5
Partition: ID-1: / raw-size: N/A size: 432.61 GiB used: 3.25 GiB (0.8%) fs: zfs
           logical: zroot/private/root
           ID-2: /boot raw-size: 1024 MiB size: 1022 MiB (99.80%) used: 252.7 MiB (24.7%) fs: vfat
           block-size: 512 B dev: /dev/sda1 maj-min: 8:1
Swap:      Alert: No swap data was found.
Sensors:   System Temperatures: cpu: 61.8 C mobo: N/A
           Fan Speeds (RPM): N/A
Info:      Processes: 181
           Uptime: 08:29:52  up 8 days 12:50,  0 users,  load average: 0.27, 0.16, 0.18
           Init: systemd v: 253 target: multi-user.target tool: systemctl Compilers: gcc: 9.5.0
           Packages: nix-default: 0 nix-sys: 630 lib: 143 nix-usr: 0 Client: Sudo v: 1.9.13p3
           inxi: 3.3.04
```



[comment]: (<<HOSTINFOS)


## Install from scratch

Download RPI image `https://hydra.nixos.org/build/201124221`

Start [Commons installation](../installation.md)

On specific **host section**

# configure nix-server, <One time> add host and public key to features/system/nix.nix
inv init-nix-serve --hosts ${TARGETIP} --hostnames ${TARGETNAME}

```
# configure nix-server
inv init-nix-server --hosts <nixos-livecd-ip>
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE
nix-store --generate-binary-cache-key rpi40.adele.local cache-priv-key.pem cache-pub-key.pem

# Update RPI and configure USB boot
inv firmware-rpi-update --hosts <nixos-livecd-ip>
```

End [Commons installation](../installation.md) with **custom task**

TODO: update rpi40, bootstore nix-server documentation and remove persistent store
