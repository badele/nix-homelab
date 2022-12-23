#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from invoke import task,run

import subprocess
import math
import re
import sys
import os
import json
import xmltodict
from xml.dom.minidom import parseString
import xml.dom.minidom
import random
import string
import shutil
from pathlib import Path
from typing import List, Any
from deploykit import DeployHost, DeployGroup
from typing import IO, Any, Callable, List, Dict, Optional, Text


ROOT = Path(__file__).parent.resolve()
os.chdir(ROOT)


RSYNC_EXCLUDES = [".git"]

OSSCAN = {
    'NixOS': [
                "Services",
                "Topologie",
                "Hardwares",
                "CPU",
                "Nix"
            ],
    'Nix': [
                "Services",
                "Topologie",
                "Hardwares",
                "CPU",
                "Nix"
            ],
    'MikroTik': [
                "Services",
    ],
    'Sagem': [
                "Services",
    ]

}

def get_hosts(hosts: str) -> List[DeployHost]:
    return [DeployHost(h, user="root") for h in hosts.split(",")]


def get_deploylist_from_homelab(hosts: str) -> List[DeployHost]:
    with open('homelab.json', 'r') as fh:
        jinfo = json.load(fh)
        hostslist = jinfo['hosts']
        
        if hosts == "":
            hostnames = hostslist.keys()
        else:
            hostnames = hosts.split(",")

        deploylist = []
        for hn in hostnames:
            dh = DeployHost(
                hostslist[hn]['ipv4'], 
                user="root",
                meta=dict(
                    hostname=hn,
                    os=hostslist[hn]['os']
                    )
            )
            deploylist.append(dh)

    return deploylist


def color_text(code: int, file: IO[Any] = sys.stdout) -> Callable[[str], None]:
    def wrapper(text: str) -> None:
        if sys.stderr.isatty():
            print(f"\x1b[{code}m{text}\x1b[0m", file=file)
        else:
            print(text, file=file)

    return wrapper


warn = color_text(31, file=sys.stderr)
info = color_text(32)


##############################################################################
# Tasks
##############################################################################

@task
def firmware_rpi_update(c, hosts):
    for h in get_hosts(hosts):
        _firmware_rpi_update(h)

@task
def ssh_init_host_key(c, hosts, hostnames):
    """
    Init ssh host key from nixos installation cd => inv ssh-init-host-key --hosts 192.168.0.1 --hostnames bootstore
    """
    h = get_hosts(hosts)
    hn = hostnames.split(',')

    for idx in range(len(h)):
        _ssh_init_host_key(h[idx], hn[idx])


@task
def disk_format(c, hosts, disk, mirror="", mode="GPT", password=""):
    """
    Format disks with zfs => inv disk-format --hosts new-hostname --disks /dev/sda [--mirror /dev/sdb]
    """

    for h in get_hosts(hosts):
        _format_disks(h, disk, mirror, mode, password)
        _disk_mount(h, mirror != "", password)


@task
def disk_mount(c, hosts, mirror="", password=""):
    """
    Mount disks from the installer => inv mount-disks --hosts new-hostname
    """
    for h in get_hosts(hosts):
        _disk_mount(h, mirror, password)


@task
def sync_homelab(c, hosts):
    """
    rsync currently local homelab project to future nixos installation => inv rsync-homelab --hosts 192.168.0.1
    """
    for h in get_hosts(hosts):
        _sync_homelab({h.host})

@task
def nixos_generate_config(c, hosts, hostnames, confname):
    """
    Generate hardware configuration for the host
    """

    h = get_hosts(hosts)
    hn = hostnames.split(',')

    for idx in range(len(h)):
        _nixos_generate_config(h[idx], hn[idx], confname)

@task
def nixos_install(c, hosts, flakeattr):
    """
    install nixos => inv nixos-install --hosts 192.168.0.1 --flakeattr bootstore
    """
    for h in get_hosts(hosts):
        # Sync project
        info("Sync homelab project")
        _sync_homelab(h)

        # Install nixos
        info("Install NixOS")
        h.run(
            f"cd /mnt/nix-homelab && nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c nixos-install --verbose --flake .#{flakeattr} && sync"
        )

@task
def deploy(c, hosts=""):
    """
    Deploy to all servers =>inv deploy --hosts <hostip/hostname> 
    """
    _deploy_nixos(get_hosts(hosts))        


@task 
def init_nix_serve(c,hosts, hostnames):
    """
    Init nix-server private & public key on /persist/host/data/nix-serve
    """

    h = get_hosts(hosts)
    hn = hostnames.split(',')

    for idx in range(len(h)):
        _init_nix_serve(h[idx], hn[idx])


@task
def doc_generate_all_pages(c):
    """
    generate all homelab documentation
    """

    _doc_update_hosts_pages()
    _doc_update_main_project_page()


@task
def doc_generate_main_page(c):
    """
    generate main homelab page
    """

    _doc_update_main_project_page()


@task
def doc_generate_hosts_pages(c):
    """
    generate all homelab hosts page
    """

    _doc_update_hosts_pages()

@task
def scan_all_hosts(c,hosts=""):
    """
    Retrieve all hosts system infromations
    """ 
    deploylist = get_deploylist_from_homelab(hosts)
    _scan_all_hosts(deploylist)


##############################################################################
# Functions
##############################################################################


def _format_disks(host: DeployHost, disk: str,mirror: str, mode: str, zfspassphrase: str) -> None:
    # format disk in hybrid mode (GPT and MBR) with as follow :
    # - partition 1 MBR/EFI boot partition
    # - partition 2 swap partition for system with few RAM
    # - partition 3 zfs partition

    # Umount all /mnt
    host.run(f"umount -R /mnt",check=False)

    # swapoff
    host.run(f'swapoff {disk}2',check=False)
    if mirror:
        host.run(f'swapoff {mirror}2',check=False)

    # Check previous zfs volumes
    r = host.run(f"zpool list | grep 'zroot'",check=False)
    if r.returncode==0:
        host.run("""
        zfs destroy -r zroot
        zpool destroy zroot
        """)

    # Wipe & Partitioning
    host.run(f"sgdisk -Z -n 1:2048:+1G -n 2:+0:+8G -N 3 -t 1:ef00 -t 2:8200 -t 3:8304 {disk}")

    # For legacy bios
    if mode=="MBR":
        host.run(f"sgdisk -m 1:2:3 {disk}")


    # Clone partition [If mirror mode]
    if mirror:
        host.run(f'sfdisk --dump {disk} | sfdisk {mirror}')

    zdisks = f"{disk}3 {mirror}3".strip()
    # Create ZFS pool
    if mirror:
        host.run(f"zpool create -f -o ashift=12 -O mountpoint=none zroot mirror {zdisks}")
    else:
        host.run(f"zpool create -f -o ashift=12 -O mountpoint=none zroot {zdisks}")

    # Format boot
    host.run(f"""
    mkfs.vfat {disk}1 -n BOOT_1ST
    test -n "{mirror}" && mkfs.vfat {mirror}1 -n BOOT_2ND
    """)

    # swap
    host.run(f"""
    mkswap {disk}2 -L SWAP_1ST
    mkswap {mirror}2 -L SWAP_2ND
    """)


    # public volumes
    host.run("""
    zfs create -o mountpoint=none -o canmount=off zroot/public
    zfs create -o mountpoint=legacy -o canmount=on -o atime=off zroot/public/nix
    zfs create -o mountpoint=legacy -o canmount=on -o atime=off zroot/public/nix-homelab
    """)

    # private volumes(encrypted)
    zfspool = "public"
    if zfspassphrase:
        host.run(f"echo '{zfspassphrase}' | zfs create -o mountpoint=none -o canmount=off -o encryption=aes-256-gcm -o keyformat=passphrase -o keylocation=prompt zroot/private")
        zfspool = "private"

    # Create private or public volume
    host.run(f"""
    zfs create -o mountpoint=legacy -o canmount=on zroot/{zfspool}/root
    zfs create -o mountpoint=legacy -o canmount=on zroot/{zfspool}/data
    zfs create -o mountpoint=legacy -o canmount=off zroot/{zfspool}/persist
    zfs create -o mountpoint=legacy -o canmount=on zroot/{zfspool}/persist/host
    zfs create -o mountpoint=legacy -o canmount=on zroot/{zfspool}/persist/user
    """)

    # Show encrypted volumes
    host.run(f'zfs get encryption')


def _disk_mount(host: DeployHost,mirror: bool, zfspassphrase: str) -> None:
    # Umount all volumes
    host.run(f"umount -R /mnt",check=False)

    # Re-import zpool informations
    host.run(f"zpool import -af")

    zfspool = "public"
    if zfspassphrase:
        host.run(f"echo '{zfspassphrase}' | zfs load-key zroot/private",check=False)
        zfspool = "private"

    # Import volumes
    host.run(f"""  
    mount -t zfs zroot/{zfspool}/root /mnt
    mkdir -p /mnt/{{boot,boot-fallback,nix,nix-homelab,data,persist/host,persist/user}}
    mount /dev/disk/by-label/BOOT_1ST /mnt/boot
    test -n "{mirror}" && mount /dev/disk/by-label/BOOT_2ND /mnt/boot-fallback
    mount -t zfs zroot/public/nix /mnt/nix
    mount -t zfs zroot/public/nix-homelab /mnt/nix-homelab
    mount -t zfs zroot/{zfspool}/data /mnt/data
    mount -t zfs zroot/{zfspool}/persist/host /mnt/persist/host
    mount -t zfs zroot/{zfspool}/persist/user /mnt/persist/user
    """)

    # Mount swap
    host.run(f"""
swapon /dev/disk/by-label/SWAP_1ST
test -n "{mirror}" && swapon /dev/disk/by-label/SWAP_2ND
mount -o remount,nr_inodes=0,size=6G /nix/.rw-store
swapon --show
""",check=False)

def _firmware_rpi_update(host: DeployHost) -> None:
    ## USB boot configuration

    host.run(f"mkdir -p /firmware")
    host.run(f"mount /dev/disk/by-label/FIRMWARE /firmware",check=False)
    host.run(f"""  
    nix-shell -p raspberrypi-eeprom --run "BOOTFS=/firmware FIRMWARE_RELEASE_STATUS=stable rpi-eeprom-update -d -a"
    cat <<EOF > /tmp/boot_nixos.conf
[all]
BOOT_UART=0
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
BOOT_ORDER=0xf14
EOF

    nix-shell -p raspberrypi-eeprom --run "BOOTFS=/firmware FIRMWARE_RELEASE_STATUS=stable rpi-eeprom-update --apply /tmp/boot_nixos.conf"
    """)


def _ssh_init_host_key(host: DeployHost, hostname: str) -> None:
    # Copy to nixos system
    host.run("""
    install -m400 --target /mnt/etc/ssh -D /etc/ssh/ssh_host_*
    chmod 444 /mnt/etc/ssh/ssh_host_*.pub
    """)
    #host.run("chmod 444 /mnt/etc/ssh/ssh_host_*.pub")

    # Generate age key
    host.run("""
    # mkdir -p ~/.config/sops/age 
    # nix-shell -p ssh-to-age --command "ssh-to-age --private-key -i /mnt/etc/ssh/ssh_host_ed25519_key -o ~/.config/sops/age/keys.txt"
    nix-shell -p ssh-to-age --command "ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub -o /tmp/ssh-to-age.txt"
    """
    )

    # Copy ssh pub to git repository
    info("copy public ssh & age key")
    run(f"""
    mkdir -p ./hosts/{hostname}
    scp root@{host.host}:/mnt/etc/ssh/ssh_host_*.pub ./hosts/{hostname}    
    scp root@{host.host}:/tmp/ssh-to-age.txt ./hosts/{hostname}
    """)

def _nixos_generate_config(host: DeployHost, hostname: str, confname: str, ) -> None:
    
    confpath = f'modules/hardware/{confname}.nix'
    if not os.path.exists(confpath):
        host.run("""
        nixos-generate-config --dir /tmp/hw --root /mnt
        """)

        info(f"copy hardware-configuration.nix to {confpath}")
        run(f"""
        scp root@{host.host}:/tmp/hw/hardware-configuration.nix {confpath}
        """)

# Remove .git (for ignoring dirty message), no git add needed :)
def _sync_homelab(host: DeployHost) -> None:
    run(f"rsync --delete {' --exclude '.join([''] + RSYNC_EXCLUDES)} -ar . root@{host.host}:/mnt/nix-homelab/")    


def _init_nix_serve(host: DeployHost, hostname: str) -> None:
    host.run(f"""
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
nix-store --generate-binary-cache-key {hostname}.adele.lan cache-priv-key.pem cache-pub-key.pem
""")


def _host_hardware_discovery(h: DeployHost) -> None:
    with open('homelab.json', 'r') as fr:
        jinfo = json.load(fr)
        hosts = jinfo['hosts']

        # Create 
        hn = h.meta.get("hostname")
        run(f"mkdir -p docs/hosts/{hn}")
        
        if not os.system(f"ping -c 1 -w 1 {h.host}"):
            if hn and h.meta.get("os") in ["NixOS", "Nix"]:
                
                h.run("""
                rm -rf /tmp/hw
                mkdir -p /tmp/hw
                """,
                check=False)

            for dn in OSSCAN[hosts[hn]["os"]]:
                
                # For non NixOS installation
                # TODO: find beautifull solution (.bash_profile & co)
                PREFIX_COMMAND="source /etc/bashrc ; LC_ALL=C"
                match dn:
                    case "Nix":
                        h.run(f"{PREFIX_COMMAND} nix-shell -p nix-info --run 'nix-info -m' > /tmp/hw/{dn}.txt")
                        run(f'scp root@{h.host}:/tmp/hw/{dn}.txt docs/hosts/{hn}/{dn.lower()}.txt')
                    case "Hardwares":
                        h.run(f"{PREFIX_COMMAND} nix-shell -p 'inxi.override {{ withRecommends = true; }}' --run 'sudo inxi -F -a -i --slots -xxx -c0 -i -m --filter' > /tmp/hw/{dn}.txt")
                        run(f'scp root@{h.host}:/tmp/hw/{dn}.txt docs/hosts/{hn}/{dn.lower()}.txt')
                    case "CPU":
                        h.run(f"{PREFIX_COMMAND} lscpu > /tmp/hw/{dn}.txt")
                        run(f'scp root@{h.host}:/tmp/hw/{dn}.txt docs/hosts/{hn}/{dn.lower()}.txt')
                    case "Topologie":
                        res = h.run(f"{PREFIX_COMMAND} nix-shell -p hwloc --run 'sudo lstopo -f /tmp/hw/{hn}.lstopo.svg'")
                        run(f"scp root@{hosts[hn]['ipv4']}:/tmp/hw/{hn}.lstopo.svg docs/hosts/{hn}/{dn.lower()}.svg")
                    case "Services":
                        res = run(f"{PREFIX_COMMAND} nix-shell -p nmap --run 'sudo nmap --version-intensity 0 -sV {hosts[hn]['ipv4']} -oX -'")
                        
                        dom = parseString(res.stdout)

                        xpars = xmltodict.parse(res.stdout)
                        try:
                            ports = xpars['nmaprun']['host']['ports']['port']

                            if isinstance(ports,dict):
                                ports = [ports]

                            # Remove sensible or unimportant values
                            for idx in range(len(ports)):
                                # State
                                if 'state' in ports[idx]:
                                    del ports[idx]['state']
                                
                                # service elements
                                if 'service' in ports[idx] :
                                    for value in ['@version', '@servicefp','@method', '@conf', 'cpe']:
                                        if value in ports[idx]['service']:
                                            del ports[idx]['service'][value]

                            jcontent = json.dumps(ports)

                            with open(f"docs/hosts/{hn}/{dn.lower()}.json", 'w') as fw:
                                fw.write(jcontent)
                        except KeyError:
                            pass

def _deploy_nixos(hosts: List[DeployHost]) -> None:
    """
    Deploy to all hosts in parallel
    """
    g = DeployGroup(hosts)

    def deploy(h: DeployHost) -> None:
        with open('homelab.json', 'r') as f:
            jinfo = json.load(f)
            hosts = jinfo['hosts']

            # Search host by ip
            hostname = None
            for hn in hosts:
                if 'ipv4' in hosts[hn] and  hosts[hn]['ipv4'] == h.host:
                    hostname = hn
                    break

        h.run_local(
            f"rsync --delete {' --exclude '.join([''] + RSYNC_EXCLUDES)} -ar . {h.user}@{h.host}:/nix-homelab/"
        )

        if hostname:
            cmd = f"cd /nix-homelab && nixos-rebuild switch --fast --option accept-flake-config true --option keep-going true --flake .#{hostname}"
            h.run(cmd)

            h.meta['hostname'] = hostname
            h.meta['isnix'] = True
            _host_hardware_discovery(h)

    g.run_function(deploy)


# Replace the content marker
def _replace_content(content: str, marker: str, newcontent) -> str:
    newcontent = f'''[comment]: (>>{marker})

{newcontent}

[comment]: (<<{marker})'''

    result = re.sub(rf'\[comment\]: \(\>\>{marker}\).*\[comment\]\: \(\<\<{marker}\)',newcontent, content,  flags=re.DOTALL | re.M)
    
    return result


# Update the main README.md project page
def _doc_update_main_project_page() -> None:

    with open('homelab.json', 'r') as f:
        jinfo = json.load(f)
        hosts = jinfo['hosts']

    # Header table
    table = '''<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>Arch</th>
        <th>OS</th>
        <th>CPU</th>
        <th>Memory</th>
        <th>Disk</th>
        <th>Description</th>
    </tr>'''

    # Hosts loop
    for hn in hosts:
        with open(f'docs/hosts/{hn}/summaries.json', 'r') as fs:
            sinfo = json.load(fs)

            table += f'''<tr>
        <td><a href="./docs/hosts/{hn}.md"><img width="32" src="{hosts[hn]["icon"]}"></a></td>
        <td><a href="./docs/hosts/{hn}.md">{hn}</a>&nbsp;({hosts[hn]["ipv4"]})</td>
        <td>{sinfo["cpu"]["arch"]}</td>
        <td>{hosts[hn]["os"]}</td>
        <td>{sinfo["cpu"]["nb"]}</td>
        <td>{sinfo["memory"]}</td>
        <td>{sinfo["disk"]}</td>
        <td>{hosts[hn]["description"]}</td>
    </tr>'''

    table += "</table>"

    # Read readme.md content
    with open('README.md', 'r') as fr:
        content = fr.read().rstrip()

    res = run(f"nix-shell -p tree --run 'tree --noreport'")
    folders = f'''```
{res.stdout}
```
'''

    # Replace content
    newcontent = _replace_content(content,"HOSTS",table)
    newcontent = _replace_content(newcontent,"FOLDERS",folders)

    # Write new content
    with open('README.md', 'w') as fw:
        fw.write(newcontent)


def _scan_all_hosts(deploylist:List[DeployHost]) -> None:

    for dh in deploylist:
        _host_hardware_discovery(dh)


def _doc_update_hosts_pages() -> None:
    with open('homelab.json', 'r') as fh:
        jinfo = json.load(fh)
        hosts = jinfo['hosts']

        for hn in hosts:
            # Readme name
            rname = f'docs/hosts/{hn}.md'

            # Clone template if doc not exists
            if not os.path.exists(rname):
                shutil.copyfile('docs/hosts/host.tpl', rname)

            # Read readme.md content
            with open(rname, 'r') as fr:
                content = fr.read().rstrip()

                hinfo = ""
                sinfo = {
                    "memory": "",
                    "disk": "",
                    "kernel": "",
                    "cpu": {
                        "arch": "",
                        "model": "",
                        "nb": "",
                        "bits": 0,
                        "bogomips": 0
                    }
                }
                for dn in OSSCAN[hosts[hn]["os"]]:
                    output = ""
                    match dn:
                        case "CPU":
                            filename = f'docs/hosts/{hn}/{dn.lower()}.txt'
                            if os.path.exists(filename):
                                with open(filename, 'r') as fr:
                                    cpu_content = fr.read().strip()

                                    # CPU architecture
                                    m = re.search('Architecture:\s+(.*)',cpu_content,flags=re.M)
                                    if m:
                                        sinfo['cpu']['arch'] = m.group(1)
                                    
                                    
                                    # CPU model
                                    m = re.search('Model name:\s+(.*)',cpu_content,flags=re.M)
                                    if m:
                                        sinfo['cpu']['model'] = m.group(1)

                                    # CPU number
                                    m = re.search('CPU\(s\):\s+([0-9]+)',cpu_content,flags=re.M)
                                    if m:
                                        sinfo['cpu']['nb'] = m.group(1)

                                    # CPU cores
                                    m = re.search('BogoMIPS:\s+([0-9]+)',cpu_content,flags=re.M)
                                    if m:
                                        sinfo['cpu']['bogomips'] = round(int(m.group(1)))
                                        
                                    

                        case "Hardwares":
                            filename = f'docs/hosts/{hn}/{dn.lower()}.txt'
                            if os.path.exists(filename):
                                with open(filename, 'r') as fr:
                                    hw_content = fr.read().strip().replace('\\','~')

                                    # Memory
                                    m = re.search('Memory:.*RAM: total: .*?([0-9]+\.[0-9]+) GiB',hw_content,flags=re.M)
                                    if m:
                                        sinfo['memory'] = f'{math.floor(float(m.group(1))*1.073741824)} Go'

                                    # Disk
                                    m = re.search('Local Storage:.*?total.*?: ([0-9]+\.[0-9]+ \w?iB)',hw_content,flags=re.M)
                                    if m:
                                        sinfo['disk'] = m.group(1)
                                    
                                    # CPU bits
                                    m = re.search('CPU: .*?bits: (.*?) \w+:',hw_content,flags=re.M)
                                    if m:
                                        sinfo['cpu']['bits'] = m.group(1)

                                    # Kernel
                                    m = re.search('System: .*?Kernel: ([0-9]+\.[0-9]+\.[0-9]+)',hw_content,flags=re.M)
                                    if m:
                                        sinfo['kernel'] = m.group(1)
                                    

                                    output = f'''```
{hw_content}
```
'''
                        case "Topologie":
                                 output = f'''
![hardware topology](https://raw.githubusercontent.com/badele/nix-homelab/master/docs/hosts/{hn}/topologie.svg)
 '''

                        case "Services":
                            filename = f'docs/hosts/{hn}/{dn.lower()}.json'

                            if os.path.exists(filename):
                                with open(filename, 'r') as fr:
                                    frs = fr.read().strip().replace('\\','~')
                                    services = json.loads(frs)


                                    output = '''| Port | Service | Product | Extra info |
| ------ | ------ |------ |------ |
'''

                                    for svc in services:
                                        proto = svc["@protocol"]
                                        port = svc["@portid"]
                                        
                                        name = svc["service"].get("@name","")
                                        product = svc["service"].get("@product","")
                                        extrainfo = svc["service"].get("@extrainfo","")
                                    
                                        output += f"|{port}|{name}|{product}|{extrainfo}|\n"
                                    output += "\n"

                    if output != "":
                        hinfo += f'''
### {dn}

{output}
        '''

                with open(f'docs/hosts/{hn}/summaries.json', 'w') as fw:
                    fw.write(json.dumps(sinfo))

                # Replace content
                newcontent = _replace_content(content,"HOSTINFOS",hinfo)

            # Write new content
            with open(rname, 'w') as fw:
                fw.write(newcontent)
