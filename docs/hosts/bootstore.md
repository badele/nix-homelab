# Host informations

This page generated by `inv docs.all-pages`

## Hardware and system informations

[comment]: (>>HOSTINFOS)


### Topologie


![hardware topology](https://raw.githubusercontent.com/badele/nix-homelab/master/docs/hosts/bootstore/topologie.svg)
 
        
### Hardwares

```
System:    Kernel: 5.15.82 x86_64 bits: 64 compiler: gcc v: 11.3.0 
           parameters: BOOT_IMAGE=(hd0,msdos1)//kernels/w1lg3hl130dha3y8myac7rgpr5ibzbgq-linux-5.15.82-bzImage 
           init=/nix/store/54m3vkjv7nizllfhakmyvsb1h2clz823-nixos-system-bootstore-23.05.20221216.757b822/init 
           nohibernate loglevel=4 
           Console: N/A Distro: NixOS 23.05 (Stoat) 
Machine:   Type: Desktop System: HP product: ProLiant MicroServer v: N/A serial: <filter> Chassis: 
           type: 7 serial: N/A 
           Mobo: N/A model: N/A serial: N/A BIOS: HP v: O41 date: 07/29/2011 
Memory:    RAM: total: 7.65 GiB used: 4.57 GiB (59.7%) 
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
           IP v4: <filter> type: dynamic noprefixroute scope: global broadcast: <filter> 
           WAN IP: <filter> 
RAID:      Device-1: zroot type: zfs status: ONLINE level: mirror-0 size: 1.8 TiB free: 1.79 TiB 
           allocated: 4.43 GiB 
           Components: Online: N/A 
Drives:    Local Storage: total: raw: 3.64 TiB usable: 5.44 TiB used: 4.48 GiB (0.1%) 
           ID-1: /dev/sda maj-min: 8:0 vendor: Seagate model: ST2000DM001-1ER164 
           family: Barracuda 7200.14 (AF) size: 1.82 TiB block-size: physical: 4096 B 
           logical: 512 B sata: 3.1 speed: 3.0 Gb/s rotation: 7200 rpm serial: <filter> rev: CC25 
           temp: 29 C scheme: MBR 
           SMART: yes state: enabled health: PASSED on: 2y 142d 7h cycles: 53 read: 67.24 TiB 
           written: 19.41 TiB Pre-Fail: attribute: Spin_Retry_Count value: 100 worst: 100 
           threshold: 97 
           ID-2: /dev/sdb maj-min: 8:16 vendor: Seagate model: ST2000DM008-2FR102 
           family: BarraCuda 3.5 (SMR) size: 1.82 TiB block-size: physical: 4096 B logical: 512 B 
           sata: 3.1 speed: 3.0 Gb/s rotation: 7200 rpm serial: <filter> rev: 0001 temp: 31 C 
           scheme: MBR 
           SMART: yes state: enabled health: PASSED on: 352h+14m+37.741s cycles: 13 
           read: 11.46 GiB written: 92.95 GiB Pre-Fail: attribute: Spin_Retry_Count value: 100 
           worst: 100 threshold: 97 
Partition: ID-1: / raw-size: N/A size: 1.74 TiB used: 114.9 MiB (0.0%) fs: zfs 
           logical: zroot/public/root 
           ID-2: /boot raw-size: 1024 MiB size: 1022 MiB (99.80%) used: 57.2 MiB (5.6%) fs: vfat 
           block-size: 512 B dev: /dev/sda1 maj-min: 8:1 
Swap:      Kernel: swappiness: 60 (default) cache-pressure: 100 (default) 
           ID-1: swap-1 type: partition size: 8 GiB used: 0 KiB (0.0%) priority: -2 dev: /dev/sdb2 
           maj-min: 8:18 
           ID-2: swap-2 type: partition size: 8 GiB used: 0 KiB (0.0%) priority: -3 dev: /dev/sda2 
           maj-min: 8:2 
Sensors:   System Temperatures: cpu: 38.5 C mobo: N/A 
           Fan Speeds (RPM): N/A 
Info:      Processes: 178 
           Uptime: 17:34:48  up 11 days  5:53,  1 user,  load average: 0.67, 0.35, 0.20 wakeups: 0 
           Init: systemd v: 252 target: multi-user.target tool: systemctl Compilers: gcc: 11.3.0 
           Packages: nix-default: 0 nix-sys: 321 lib: 51 nix-usr: 0 Client: Sudo v: 1.9.12p1 
           inxi: 3.3.04
```

        
### Services

| Port | Service | Product | Extra info |
| ------ | ------ |------ |------ |


        

[comment]: (<<HOSTINFOS)

## Install from scratch

Download RPI image `https://hydra.nixos.org/build/201124221`

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
export TARGETIP=192.168.0.29
export TARGETNAME=bootstore

ssh-copy-id root@${TARGETIP}
 inv disk-format --hosts ${TARGETIP} --disk /dev/sda --mirror /dev/sdb --mode MBR
 [Optional] inv disk-mount --hosts ${TARGETIP} --mirror true --password "<zfspassword>"
inv ssh-init-host-key --hosts ${TARGETIP} --hostnames ${TARGETNAME}
inv wireguard.keys # Add to wireguard-privatekey (./hosts/bootstore/secrets.yml )
inv nixos-generate-config --hosts ${TARGETIP} --hostnames ${TARGETNAME} --name hp-proliant-microserver-n40l

# Add hosts/bootstore/ssh-to-age.txt content to .sops.yaml
# Add root password key to ./hosts/bootstore/secrets.yml 
echo 'yourpassword' | mkpasswd -m sha-512 -s

# Re-encrypt all keys for the previous host
sops updatekeys ./hosts/${TARGETNAME}/secrets.yml

##########################################################
# Nix serve binary cache
##########################################################

# configure nix-server, <One time> add host and public key to modules/system/nix.nix 
inv init-nix-serve --hosts ${TARGETIP} --hostnames ${TARGETNAME}

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