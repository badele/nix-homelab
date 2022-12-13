# RPI40

## Install from scratch

Download RPI image `https://hydra.nixos.org/build/201124221`

```
# Change keymap & root password
sudo -i
loadkeys fr
passwd 

# WI-FI
systemctl start wpa_supplicant
wpa_cli
add_network
set_network 0 ssid "ssid_name"
set_network 0 psk "password"
enable_network 0

# From other computer, enter to deploy environment
# NOTE: Use <SPACE> before command for not storing command in bash history (for secure your passwords)
nix develop
ssh-copy-id root@<nixos-livecd-ip>
 inv firmware-tpi-update --hosts <nixos-livecd-ip> 
 inv disk-format --hosts <nixos-livecd-ip> --disks /dev/sda --password <zfspassword>
inv ssh-init-host-key --hosts <nixos-livecd-ip> --hostnames <hostname>

# Add password key to ./hosts/<hostname>/secrets.yml 
echo 'yourpassword' | mkpasswd -m sha-512 -s

# Re-encrypt all keys for the previous host
sops updatekeys ./hosts/<hostname>/secrets.yml

# configure nix-server
inv init-nix-server --hosts <nixos-livecd-ip>
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
nix-store --generate-binary-cache-key rpi40.adele.local cache-priv-key.pem cache-pub-key.pem

# install
inv install-nixos --hosts <nixos-livecd-ip> --flakeattr <hostname>

# Update RPI and configure USB boot
inv firmware-rpi-update --hosts <nixos-livecd-ip>


# Get configuration
cd /tmp
nix develop
git clone https://github.com/badele/nix-config.git
cd nix-config

# [Optional] Copy your previous borg backups at /tmp/persist

# Install bootstrap
make bootstrap HOSTNAME=<hostname> 
make nixos-install TMPDIR=/mnt/data/tmp USERNAME=<username> HOSTNAME=<hostname>
reboot
make nixos-update HOSTNAME=<hostname>
make home-update USERNAME=<username> HOSTNAME=<hostname>
```

## Second install
```

```

## nix-serve
```
```

nix verify --store http://localhost:5000 --trusted-public-keys 'rpi40.adele.local:JYE85lTt2SBXUwueEftHLH/CE7INzV0zH7TWfNtIqYU=' /nix/store