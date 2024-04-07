# Host informations

This page generated with `inv docs.all-pages`


[comment]: (>>HOSTINFOS)


### Config

```text
Arch     : x86_64
CPU      : 4 x Intel(R) Core(TM) i5-4300U CPU @ 1.90GHz
BogoMIPS : 4988
RAM      : 8 Go Go
DISK     : 465.76 GiB Go
KERNEL   : 5.15.78
```

### Topologie


![hardware topology](https://raw.githubusercontent.com/badele/nix-homelab/master/docs/hosts/latino/topologie.svg)


### Hardwares

```
System:    Kernel: 5.15.78 x86_64 bits: 64 compiler: gcc v: 11.3.0
           parameters: initrd=~efi~nixos~5yzc4622rdcw9pfmg6zqjxanvpjr72an-initrd-linux-5.15.78-initrd.efi
           init=/nix/store/b4m6k9hf1rmqva6nxlkhi0qrqnw50hgf-nixos-system-latino-22.11.20221115.85d6b39/init
           nohibernate loglevel=4
           Console: tty pts/1 Distro: NixOS 22.11 (Raccoon)
Machine:   Type: Laptop System: Dell product: Latitude E5540 v: 00 serial: <filter> Chassis:
           type: 9 serial: <filter>
           Mobo: Dell model: 0H3FM5 v: A00 serial: <filter> UEFI: Dell v: A15 date: 09/27/2016
Battery:   ID-1: BAT0 charge: 25.3 Wh (100.0%) condition: 25.3/66.6 Wh (38.0%) volts: 12.7
           min: 11.1 model: SMP DELL WGCW633 type: Li-ion serial: <filter> status: Full
Memory:    RAM: total: 7.68 GiB used: 7.3 GiB (95.0%)
           Array-1: capacity: 16 GiB slots: 2 EC: None max-module-size: 8 GiB note: est.
           Device-1: DIMM A size: 4 GiB speed: 1600 MT/s type: DDR3 detail: synchronous
           bus-width: 64 bits total: 64 bits manufacturer: Samsung part-no: M471B5173QH0-YK0
           serial: <filter>
           Device-2: DIMM B size: 4 GiB speed: 1600 MT/s type: DDR3 detail: synchronous
           bus-width: 64 bits total: 64 bits manufacturer: Crucial part-no: CT51264BF160BJ.M8F
           serial: <filter>
PCI Slots: Slot: 0 type: x16 PCI Express J6B2 status: In Use length: Long
           Slot: 1 type: x1 PCI Express J6B1 status: In Use length: Short
           Slot: 2 type: x1 PCI Express J6D1 status: In Use length: Short
           Slot: 3 type: x1 PCI Express J7B1 status: In Use length: Short
           Slot: 4 type: x1 PCI Express J8B4 status: In Use length: Short
CPU:       Info: Dual Core model: Intel Core i5-4300U socket: rPGA988B bits: 64 type: MT MCP
           arch: Haswell family: 6 model-id: 45 (69) stepping: 1 microcode: 26 cache: L1: 128 KiB
           L2: 3 MiB L3: 3 MiB
           flags: avx avx2 lm nx pae sse sse2 sse3 sse4_1 sse4_2 ssse3 vmx bogomips: 19954
           Speed: 2304 MHz min/max: 800/2900 MHz base/boost: 1900/1900 volts: 1.2 V
           ext-clock: 100 MHz Core speeds (MHz): 1: 2304 2: 1932 3: 2521 4: 2045
           Vulnerabilities: Type: itlb_multihit status: KVM: VMX disabled
           Type: l1tf mitigation: PTE Inversion; VMX: conditional cache flushes, SMT vulnerable
           Type: mds mitigation: Clear CPU buffers; SMT vulnerable
           Type: meltdown mitigation: PTI
           Type: mmio_stale_data status: Unknown: No mitigations
           Type: retbleed status: Not affected
           Type: spec_store_bypass
           mitigation: Speculative Store Bypass disabled via prctl and seccomp
           Type: spectre_v1 mitigation: usercopy/swapgs barriers and __user pointer sanitization
           Type: spectre_v2 mitigation: Retpolines, IBPB: conditional, IBRS_FW, STIBP:
           conditional, RSB filling, PBRSB-eIBRS: Not affected
           Type: srbds mitigation: Microcode
           Type: tsx_async_abort status: Not affected
Graphics:  Device-1: Intel Haswell-ULT Integrated Graphics vendor: Dell driver: i915 v: kernel
           bus-ID: 00:02.0 chip-ID: 8086:0a16 class-ID: 0300
           Device-2: Microdia Laptop_Integrated_Webcam_HD type: USB driver: uvcvideo
           bus-ID: 1-1.6:3 chip-ID: 0c45:649d class-ID: 0e02
           Display: server: No display server data found. Headless machine? tty: 190x48
           Message: Advanced graphics data unavailable in console for root.
Audio:     Device-1: Intel Haswell-ULT HD Audio vendor: Dell driver: snd_hda_intel v: kernel
           bus-ID: 00:03.0 chip-ID: 8086:0a0c class-ID: 0403
           Device-2: Intel 8 Series HD Audio vendor: Dell driver: snd_hda_intel v: kernel
           bus-ID: 00:1b.0 chip-ID: 8086:9c20 class-ID: 0403
           Sound Server-1: ALSA v: k5.15.78 running: yes
           Sound Server-2: PipeWire v: 0.3.59 running: yes
Network:   Device-1: Intel Ethernet I218-LM vendor: Dell driver: e1000e v: kernel port: f080
           bus-ID: 00:19.0 chip-ID: 8086:155a class-ID: 0200
           IF: eno1 state: down mac: <filter>
           Device-2: Intel Wireless 7260 driver: iwlwifi v: kernel port: f040 bus-ID: 02:00.0
           chip-ID: 8086:08b1 class-ID: 0280
           IF: wlp2s0 state: up mac: <filter>
           IP v4: <filter> type: dynamic noprefixroute scope: global broadcast: <filter>
           IP v6: <filter> type: noprefixroute scope: link
           IF-ID-1: docker0 state: down mac: <filter>
           IP v4: <filter> scope: global broadcast: <filter>
           WAN IP: <filter>
Bluetooth: Device-1: Intel Bluetooth wireless interface type: USB driver: btusb v: 0.8
           bus-ID: 1-1.8.2:5 chip-ID: 8087:07dc class-ID: e001
           Report: rfkill ID: hci0 rfk-id: 4 state: down bt-service: not found rfk-block:
           hardware: no software: no address: see --recommends
RAID:      Hardware-1: Intel 82801 Mobile SATA Controller [RAID mode] driver: ahci v: 3.0
           port: f060 bus-ID: 00:1f.2 chip-ID: 8086.282a rev: 04 class-ID: 0104
           Device-1: latino type: zfs status: ONLINE level: linear size: 464 GiB free: 427 GiB
           allocated: 36.8 GiB
           Components: Online: N/A
Drives:    Local Storage: total: raw: 465.76 GiB usable: 929.76 GiB used: 37.36 GiB (4.0%)
           ID-1: /dev/sda maj-min: 8:0 vendor: Samsung model: SSD 850 EVO 500GB family: based SSDs
           size: 465.76 GiB block-size: physical: 512 B logical: 512 B sata: 3.1 speed: 6.0 Gb/s
           rotation: SSD serial: <filter> rev: 2B6Q temp: 43 C scheme: GPT
           SMART: yes state: enabled health: PASSED on: 367d 15h cycles: 1352 written: 8.46 TiB
Partition: ID-1: / raw-size: N/A size: 431.46 GiB used: 18.65 GiB (4.3%) fs: zfs
           logical: latino/private/root
           ID-2: /boot raw-size: 512 MiB size: 511 MiB (99.80%) used: 31.5 MiB (6.2%) fs: vfat
           block-size: 512 B dev: /dev/sda1 maj-min: 8:1
Swap:      Alert: No swap data was found.
Sensors:   System Temperatures: cpu: 66.0 C mobo: 43.0 C sodimm: SODIMM C
           Fan Speeds (RPM): cpu: 3495
Info:      Processes: 262
           Uptime: 22:30:04  up 1 day 13:36,  1 user,  load average: 3.73, 2.69, 2.50 wakeups: 1
           Init: systemd v: 251 target: multi-user.target tool: systemctl Compilers: gcc: 11.3.0
           Packages: 1195 nix-default: 271 lib: 1 nix-sys: 653 lib: 150 nix-usr: 271 lib: 28
           Client: Sudo v: 1.9.12p1 inxi: 3.3.04
```



[comment]: (<<HOSTINFOS)

## Install from scratch

```console
##########################################################
# From NixOS LiveCD installation
##########################################################

# Change keymap & root password
sudo -i
loadkeys fr
passwd

# [Optional] WI-FI
systemctl start wpa_supplicant
wpa_cli
add_network
set_network 0 ssid "ssid_name"
set_network 0 psk "password"
enable_network 0

# Get LiveCD nixos installation IP
ip a

##########################################################
# From other computer, enter to deploy environment
##########################################################

# NOTE: Use <SPACE> before command for not storing command in bash history (for secure your passwords)
nix develop
export TARGETIP=192.168.254.200
export TARGETNAME=sadhome
export ZFSPASSWORD="<zfspassword>"

ssh-copy-id root@${TARGETIP}

# Disk initialisation (some examples)
qinv init.disk-format --hosts ${TARGETIP} --disk /dev/sda --mode MBR --password "${ZFSPASSWORD}"
inv init.disk-format --hosts ${TARGETIP} --disk /dev/nvme0n1  --mode EFI
or
inv nix.disk-mount --hosts ${TARGETIP} --password "${ZFSPASSWORD}"

inv init.ssh-init-host-key --hosts ${TARGETIP} --hostnames ${TARGETNAME}
inv init.nixos-generate-config --hosts ${TARGETIP} --hostnames ${TARGETNAME}
# Replace UUID in the hosts/<hostname>/hardware-configuration.nix
# (generally boot & swap UUID)

# Add hosts/${TARGETNAME}/ssh-to-age.txt in &hosts section in the .sops.yaml file
# Add root password key to ./hosts/${TARGETNAME}/secrets.yml
echo 'yourpassword' | mkpasswd -m sha-512 -s
sops ./hosts/${TARGETNAME}/secrets.yml
[Optional] sops updatekeys ./hosts/${TARGETNAME}/secrets.yml # Re-encrypt all keys for the previous host

####################################################
# Execute some specific host installation
# - ex: nix-server cache installation (bootstore)
####################################################

####################################################
# Execute your custom task here, exemple:
# - Restore persist borgbackup
# - Configure some program (private key generation)
####################################################

# Add hostname section in homelab.json
# Add host in flake.nix
# Configure hosts/<hostname>/default.nix and hosts/<hostname>/hardware-configuration.nix

# NixOS installation
inv init.nixos-install --hosts ${TARGETIP} --flakeattr ${TARGETNAME}

# Configuration
reboot
nmtui (wireless configuration
```

## Update

```console
inv nixos.deploy --hostnames sadhome
inv home.deploy --username badele --hostnames sadhome
inv home.deploy --username sadele --hostnames sadhome
```
