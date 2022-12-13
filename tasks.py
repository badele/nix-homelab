#!/usr/bin/env python3

from invoke import task,run

import subprocess
import sys
import os
import json
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

def get_hosts(hosts: str) -> List[DeployHost]:
    return [DeployHost(h, user="root") for h in hosts.split(",")]


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
def disk_format(c, hosts, disks, password=""):
    """
    Format disks with zfs => inv format-disks --hosts new-hostname --disks /dev/sda (mirrored if multiples disks)
    """

    DISKS= disks.split(',')
    MIRROR=len(DISKS)>1

    if not MIRROR:
        for h in get_hosts(hosts):
            _format_disks(h, DISKS[0],password)
            _disk_mount(h,password)


@task
def disk_mount(c, hosts,password=""):
    """
    Mount disks from the installer => inv mount-disks --hosts new-hostname
    """
    for h in get_hosts(hosts):
        _disk_mount(h,password)


@task
def sync_homelab(c, hosts):
    """
    rsync currently local homelab project to future nixos installation => inv rsync-homelab --hosts 192.168.0.1
    """
    for h in get_hosts(hosts):
        _sync_homelab({h.host})


@task
def install_nixos(c, hosts, flakeattr):
    """
    install nixos => inv install-nixos --hosts 192.168.0.1 --flakeattr bootstore
    """
    for h in get_hosts(hosts):
        # Sync project
        info("Sync homelab project")
        _sync_homelab(h)

        # Install nixos
        info("Install NixOS")
        h.run(
            f"cd /tmp/homelab && nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c nixos-install --flake .#{flakeattr} && sync"
        )

@task
def deploy(c, hosts=""):
    """
    Deploy to all servers =>inv deploy --hosts <hostip/hostname> 
    """
    _deploy_nixos(get_hosts(hosts))        


@task 
def init_nix_serve(c,hosts=""):
    """
    Init nix-server private & public key on /persist/host/data/nix-serve
    """
    for h in get_hosts(hosts):
        _init_nix_serve(h)


@task
def doc_generate(c):
    """
    generate homelab doc
    """
    _doc_generate()

##############################################################################
# Functions
##############################################################################


def sfdisk_json(host: DeployHost, dev: str) -> List[Any]:
    out = host.run(f"sfdisk --json {dev}", stdout=subprocess.PIPE)
    data = json.loads(out.stdout)
    return data["partitiontable"]["partitions"]

def _format_disks(host: DeployHost, device: str, zfspassphrase: str) -> None:
    # format disk with as follow:
    # - partition 1 will be the boot partition
    # - partition 2 takes up the rest of the space and is for the system

    # Umount all /mnt
    host.run(f"umount -R /mnt",check=False)

    # Check previous zfs volumes
    r = host.run(f"zpool list | grep 'zroot'",check=False)
    if r.returncode==0:
        host.run("""
        zfs destroy -r zroot
        zpool destroy zroot
        """)

    # Wipe
    host.run(f"sgdisk -Z '{device}'") 

    # Partitioning
    host.run(f"sgdisk -Z -n 1:2048:+1G -N 2 -t 1:ef00 -t 2:8304 {device}")
    partitions = sfdisk_json(host, device)
    boot = partitions[0]["node"]
    uuid = partitions[1]["uuid"].lower()
    root_part = f"/dev/disk/by-partuuid/{uuid}"

    # Create ZFS pool
    host.run(
        f"zpool create -f -o ashift=12 -O mountpoint=none zroot {root_part}"
    )

    host.run(f"partprobe")
    host.run(f"mkfs.vfat {boot} -n NIXOS_BOOT")

    # public volumes
    host.run("""
    zfs create -o mountpoint=none -o canmount=off zroot/public
    zfs create -o mountpoint=legacy -o canmount=on -o atime=off zroot/public/nix
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


def _disk_mount(host: DeployHost,zfspassphrase: str) -> None:
    # Re-import zpool informations
    host.run(f"umount -R /mnt",check=False)
    host.run(f"zpool import -af")

    zfspool = "public"
    if zfspassphrase:
        host.run(f"echo '{zfspassphrase}' | zfs load-key zroot/private",check=False)
        zfspool = "private"

    # Import volumes
    host.run(f"""  
    mount -t zfs zroot/{zfspool}/root /mnt
    mkdir -p /mnt/{{boot,nix,data,persist/host,persist/user}}
    mount '/dev/disk/by-label/NIXOS_BOOT' /mnt/boot
    mount -t zfs zroot/public/nix /mnt/nix
    mount -t zfs zroot/{zfspool}/data /mnt/data
    mount -t zfs zroot/{zfspool}/persist/host /mnt/persist/host
    mount -t zfs zroot/{zfspool}/persist/user /mnt/persist/user
    """)


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


def _sync_homelab(host: DeployHost) -> None:
    host.run("mkdir -p /tmp/homelab")
    run(f"rsync -ar . root@{host.host}:/tmp/homelab/")    


def _init_nix_serve(host: DeployHost) -> None:
    host.run("""
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
nix-store --generate-binary-cache-key rpi40.adele.local cache-priv-key.pem cache-pub-key.pem
""")



def _deploy_nixos(hosts: List[DeployHost]) -> None:
    """
    Deploy to all hosts in parallel
    """
    g = DeployGroup(hosts)

    def deploy(h: DeployHost) -> None:
        config_dir = h.meta.get("config_dir", "/etc/nixos")
        h.run_local(
            f"rsync {' --exclude '.join([''] + RSYNC_EXCLUDES)} -vaF --delete -e ssh . {h.user}@{h.host}:{config_dir}"
        )

        flake_path = config_dir
        flake_attr = h.meta.get("flake_attr")
        if flake_attr:
            flake_path += "#" + flake_attr
        target_host = h.meta.get("target_host", "localhost")
        cmd = f"nixos-rebuild switch --fast --option accept-flake-config true --build-host localhost --target-host {target_host} --flake {flake_path} --option keep-going true"
        ret = h.run(cmd, check=False)
        # re-retry switch if the first time fails
        if ret.returncode != 0:
            ret = h.run(cmd)

    g.run_function(deploy)


def _doc_generate() -> None:
    with open('hosts/infos.json', 'r') as f:
        hosts = json.load(f)

        result=[]
        for hn in hosts:
            if os.system(f"ping -c 1 -w 1 {hosts[hn]['ipv4']}"):
                result.append(hn)

    print(result)