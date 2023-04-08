# Commons NixOS installation

Boot from NixOS live cd

```
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
export TARGETIP=<hostip>
export TARGETNAME=<hostname>

ssh-copy-id root@${TARGETIP}

# Disk initialisation (some examples)
inv init.disk-format --hosts ${TARGETIP} --disk /dev/sda --mirror /dev/sdb --mode MBR --passwd <PASSWORD> # encrypt ZFS
inv init.disk-format --hosts ${TARGETIP} --disk /dev/sda --mirror /dev/sdb --mode MBR
inv init.disk-format --hosts ${TARGETIP} --disk /dev/nvme0n1  --mode EFI
or 
inv nix.disk-mount --hosts ${TARGETIP} --password "<zfspassword>" [--mirror /dev/sdb] 

inv init.ssh-init-host-key --hosts ${TARGETIP} --hostnames ${TARGETNAME}
inv init.nixos-generate-config --hosts ${TARGETIP} --hostnames ${TARGETNAME}

# Add hosts/${TARGETNAME}/ssh-to-age.txt in &hosts section in the .sops.yaml file
# Add root password key to ./hosts/${TARGETNAME}/secrets.yml
echo 'yourpassword' | mkpasswd -m sha-512 -s

# Re-encrypt all keys for the previous host
sops ./hosts/${TARGETNAME}/secrets.yml
[Optional] sops updatekeys ./hosts/${TARGETNAME}/secrets.yml

####################################################
# Execute some specific host installation
# - ex: nix-server cache installation (bootstore)
####################################################

####################################################
# Execute your custom task here, exemple:
# - Restore persist borgbackup
# - Configure some program (private key generation)
####################################################

# Add hostname in configurations.nix with minimalModules
# Configure hosts/<hostname>/default.nix and hosts/<hostname>/hardware-configuration.nix 

# NixOS installation
inv init.nixos-install --hostnames ${TARGETIP} --flakeattr ${TARGETNAME}
```

## Update nixos & home-manager

```
inv nixos.deploy --hosts <hostname>
inv home.deploy --hosts <username@hostname>
```