#!/usr/bin/env just -f

set export

SSHPASS := "nixosusb"

# This help
@help:
    just -l -u

###############################################################################
# Installer
###############################################################################
# Create an 
[group('clan')]
@create-bootable-usb-installer USBDISK KEYMAP="us" LANGUAGE="en_US.UTF8": 
    ssh-add -L > /tmp/clan-yubikey.pub
    clan flash write --flake git+https://git.clan.lol/clan/clan-core \
    --ssh-pubkey /tmp/clan-yubikey.pub \
    --keymap fr \
    --language fr_FR.UTF-8 \
    --disk main ${USBDISK} \
    flash-installer

# Add new machine
[group('clan')]
@machine-add MACHINE:
    clan machines create {{MACHINE}} 

# Get disk ID
[group('clan')]
@machine-get-disk-id HOST PORT="22":
    ssh root@{{HOST}} -p {{PORT}} -o StrictHostKeychecking=no lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT

# log in to kanidm
[group('admin')]
@kanidm-login:
    echo "Password copied to clipboard, you can paste later"
    clan vars get houston kanidm/idm-admin-password | xclip -selection clipboard 
    (sleep 5 && echo -n | xclip -selection clipboard) &
    kanidm login --name idm_admin

# add user to kanidm
[group('admin')]
@kanidm-user-add USER DISPLAYNAME EMAIL="":
    kanidm person create {{USER}} "{{DISPLAYNAME}}"
    [ ! -z "{{EMAIL}}" ] && kanidm person update {{USER}} --mail {{EMAIL}}

# Reset user password
[group('admin')]
@kanidm-reset-user-password USER:
    # Reset user password
    kanidm person credential create-reset-token {{USER}}

###############################################################################
# Pre-commit
###############################################################################

# Setup pre-commit
[group('precommit')]
precommit-install:
    #!/usr/bin/env bash
    test ! -f .git/hooks/pre-commit && pre-commit install || true

# Update pre-commit
[group('precommit')]
@precommit-update:
    pre-commit autoupdate

# precommit check
[group('precommit')]
@precommit-check:
    pre-commit run --all-files

# Lint the project
[group('precommit')]
@lint:
    pre-commit run --all-files

###############################################################################
# Documentation
###############################################################################
# Update documentation
[group('documentation')]
@doc-update-command:
    termshot -f docs/commands.png -- just

# Update documentation
[group('documentation')]
@doc-update FILENAME="FAKEFILENAME":
    ./.pre-commit-scripts/updatedoc.ts


###############################################################################
# Debug
###############################################################################

# Repl the project
[group('debug')]
@debug-repl:
    nix repl --extra-experimental-features repl-flake .#

###############################################################################
# Flake
###############################################################################

# Show flake metadata
[group('flake')]
@flake-metadata:
    nix flake metadata

# Update the flake
[group('flake')]
@flake-update:
    nix flake update

# Sync the nix registry with the current running nix version
[group('flake')]
@flake-sync-registry:
    nix registry pin nixpkgs github:NixOS/nixpkgs/$(nix flake metadata --json | jq -r '.locks.nodes."nixpkgs".locked.rev')
    # nix flake metadata --json | jq -r '.locks.nodes."nixpkgs".locked.rev'
    # nix flake metadata --json | jq -r '.locks.nodes."home-manager".locked.rev'

# Check the nix homelab configuration
[group('flake')]
@flake-check:
    nix flake check

###############################################################################
# NIXOS installer
###############################################################################

# Create SSH key and store on passwordstore
[group('installer')]
create-ssh-key folder account save="true":
    #!/usr/bin/env bash
    mkdir -p ./configuration/{{folder}}/ssh /tmp/nix-homelab
    cleanup() {
    rm -rf "/tmp/nix-homelab"
    }
    trap cleanup EXIT

    PREFIXKEY="ssh_account_{{account}}"
    if [ ! -f ./configuration/{{folder}}/ssh/${PREFIXKEY}_ed25519.pub ]; then
        # Generate ssh keys
        ssh-keygen -q -N "" -t rsa -b 4096 -f /tmp/nix-homelab/${PREFIXKEY}_rsa_key
        ssh-keygen -q -N "" -t ed25519 -f /tmp/nix-homelab/${PREFIXKEY}_ed25519_key

        # Insert ssh keys to pass
        if [ "{{save}}" == "true" ]; then
            pass insert -m nix-homelab/{{folder}}/ssh/${PREFIXKEY}_rsa_key < /tmp/nix-homelab/${PREFIXKEY}_rsa_key
            pass insert -m nix-homelab/{{folder}}/ssh/${PREFIXKEY}_ed25519_key < /tmp/nix-homelab/${PREFIXKEY}_ed25519_key
        else
            cp /tmp/nix-homelab/${PREFIXKEY}_rsa_key ./configuration/{{folder}}/ssh
            cp /tmp/nix-homelab/${PREFIXKEY}_ed25519_key ./configuration/{{folder}}/ssh
        fi

        # Copy ssh pub keys to host configuration
        cp /tmp/nix-homelab/${PREFIXKEY}_rsa_key.pub ./configuration/{{folder}}/ssh
        cp /tmp/nix-homelab/${PREFIXKEY}_ed25519_key.pub ./configuration/{{folder}}/ssh
    fi

[private]
[group('installer')]
nixos-init-ssh-host host save="true":
    #!/usr/bin/env bash
    mkdir -p ./hosts/{{host}} /tmp/nix-homelab
    cleanup() {
    rm -rf "/tmp/nix-homelab"
    }
    trap cleanup EXIT

    if [ ! -f ./hosts/{{host}}/ssh_host_ed25519_key.pub ]; then
        # Generate ssh keys
        ssh-keygen -q -N "" -t rsa -b 4096 -f /tmp/nix-homelab/ssh_host_rsa_key
        ssh-keygen -q -N "" -t ed25519 -f /tmp/nix-homelab/ssh_host_ed25519_key

        # Insert ssh keys to pass
        if [ "{{save}}" == "true" ]; then
            pass insert -m nix-homelab/hosts/{{host}}/ssh_host_rsa_key < /tmp/nix-homelab/ssh_host_rsa_key
            pass insert -m nix-homelab/hosts/{{host}}/ssh_host_ed25519_key < /tmp/nix-homelab/ssh_host_ed25519_key
        else
            cp /tmp/nix-homelab/ssh_host_rsa_key ./hosts/{{host}}
            cp /tmp/nix-homelab/ssh_host_ed25519_key ./hosts/{{host}}
        fi

        # Copy ssh pub keys to host configuration
        cp /tmp/nix-homelab/ssh_host_rsa_key.pub ./hosts/{{host}}
        cp /tmp/nix-homelab/ssh_host_ed25519_key.pub ./hosts/{{host}}

        # Create age key from host ssh key
        ssh-to-age -i ./hosts/{{host}}/ssh_host_ed25519_key.pub -o ./hosts/{{host}}/ssh-to-age.txt
    fi

[private]
nixos-init-root-pass host:
    #!/usr/bin/env bash
    if [ ! -f ./hosts/{{host}}/ssh_host_ed25519_key.pub ]; then
        # Generate root password
        just passwd-generate | pass insert -m nix-homelab/hosts/{{host}}/accounts/root
    fi

# Init nixos host if not exists
[group('installer')]
nixos-init-host host: (nixos-init-root-pass host) (nixos-init-ssh-host host)

# Install new <hostname> to <target>:<port> system wide
[group('installer')]
nixos-install hostname targetip port="22":
    #!/usr/bin/env bash
    mkdir -p /tmp/nix-homelab
    cleanup() {
    rm -rf "/tmp/nix-homelab"
    }
    trap cleanup EXIT

    # Decrypt ssh keys
    install -d -m755 "/tmp/nix-homelab/etc/ssh"
    pass nix-homelab/hosts/{{hostname}}/ssh_host_ed25519_key > "/tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key"
    chmod 600 "/tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key"
    nixos-anywhere --extra-files /tmp/nix-homelab -p {{port}} --flake .#{{hostname}} root@{{targetip}}

[private]
nixos-command action hostname="" options="":
    sudo nixos-rebuild {{ action }} {{ options }} --fast --option accept-flake-config true --flake .#{{ hostname }}

# Nixos clean build cache and garbage unused derivations
[group('nixos')]
@nixos-garbage:
    sudo nix-collect-garbage -d

# Nixos build local host
[group('nixos')]
@nixos-build hostname="" options="":
    just nixos-command build {{ hostname }} {{ options }}

# Update NixOS on local host
[group('nixos')]
@nixos-update options="":
    just nixos-command switch "" {{ options }}

# Update on remote host
[group('nixos')]
@nixos-remote-update hostname targetip options="":
    just nixos-command switch {{hostname}} "--target-host root@{{ targetip }}" {{ options }}

[private]
home-command action:
    home-manager {{action}} --option accept-flake-config true --flake .

# Home build for local user
[group('home-manager')]
@home-build:
    just home-command build

# Home deploy local user
[group('home-manager')]
@home-deploy:
    just home-command switch

###############################################################################
# ISO & Demo
###############################################################################

# Build NixOS ISO image
[group('demo')]
@iso-build:
    nix build '.#nixosConfigurations.iso.config.system.build.isoImage'

# Init demo credentials
[group('demo')]
demo-init-credentials passwd="demopass": (nixos-init-ssh-host "demovm" "false")
    #!/usr/bin/env bash

    # Generate demo age key
    if [ ! -f ./users/demo/age-key.txt ]; then
        age-keygen -o ./users/demo/age-key.txt
    fi

    PUBLICKEY=$(head -n2 ./users/demo/age-key.txt  | tail -1 | sed 's/.*: age/age/')
    PRIVATEKEY=$(tail -1 ./users/demo/age-key.txt)
    HOSTAGEKEY=$(cat hosts/demovm/ssh-to-age.txt)

    # Add private key to sops
    if ! grep -q "$PRIVATEKEY" ~/.config/sops/age/keys.txt; then
        echo "$PRIVATEKEY" >> ~/.config/sops/age/keys.txt
    fi

    # Add public key to sops
    sed -i "s/\&demo .*/\&demo $PUBLICKEY/" .sops.yaml
    sed -i "s/\&demovm .*/\&demovm $HOSTAGEKEY/" .sops.yaml

    cat << EOF > ./hosts/demovm/secrets.tmp
    system:
        user:
            root-hash: $(echo "{{passwd}}" | mkpasswd -m sha-512 -s)
            demo-hash: $(echo "{{passwd}}" | mkpasswd -m sha-512 -s)
    EOF
    sops --input-type yaml --output-type yaml -e ./hosts/demovm/secrets.tmp > ./hosts/demovm/secrets.yml
    rm -f ./hosts/demovm/secrets.tmp

# Install new <hostname> to <target>:<port> system wide
[group('demo')]
demo-nixos-install hostname targetip port="22":
    #!/usr/bin/env bash
    mkdir -p /tmp/nix-homelab
    cleanup() {
    rm -rf "/tmp/nix-homelab"
    }
    trap cleanup EXIT

    # Copy host ssh keys
    install -d -m755 "/tmp/nix-homelab/etc/ssh"
    cp ./hosts/demovm/ssh_host_ed25519_key /tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key
    chmod 600 /tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key

    # copy demo age key
    install -d -m755 "/tmp/nix-homelab/root/.config/sops/age"
    PRIVATEKEY=$(tail -1 ./users/demo/age-key.txt)
    echo "$PRIVATEKEY" > /tmp/nix-homelab/root/.config/sops/age/keys.txt
    chmod 600 "/tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key" "/tmp/nix-homelab/root/.config/sops/age/keys.txt"
    nixos-anywhere --env-password --extra-files /tmp/nix-homelab -p {{port}} --flake .#{{hostname}} root@{{targetip}}


[private]
@demo-create-disk:
    [ -e disk-demo.raw ] || qemu-img create disk-demo.raw 20G

# Start NixOS demo from ISO image
[group('demo')]
@demo-start: demo-create-disk
    qemu-system-x86_64 -enable-kvm -smp 2 -m 4096 --bios $UEFI_FILE -device virtio-vga -net nic,model=virtio-net-pci -net user,hostfwd=tcp::2222-:22 -drive file=disk-demo.raw,format=raw -cdrom result/iso/nixos-*.iso &

# (type ESC for select boot device)
# Test NixOS installation deployment on qemu virutal machine
[group('demo')]
@demo-qemu-nixos-install: demo-init-credentials demo-start
    ssh-keygen -R "[127.0.0.1]:2222"
    just demo-nixos-install demovm 127.0.0.1 2222

# (type ESC for select boot device)
# Test NixOS update deployment on qemu virutal machine
[group('demo')]
@demo-qemu-nixos-update: demo-start
    ssh-keygen -R "[127.0.0.1]:2222"
    # Disable --fast (if you have error: cached failure of attribute)
    # Disable --fallback (if you have error: cannot build derivation)
    NIX_SSHOPTS="-l root -p 2222 -o StrictHostKeychecking=no" nixos-rebuild switch --fallback --show-trace --option accept-flake-config true --target-host 127.0.0.1 --flake .#demovm

# Stop demo vm test
[group('demo')]
@demo-stop:
    pkill qemu

# Clean demo vm test
[group('demo')]
@demo-clean:
    rm -f disk-demo.raw

###############################################################################
# Secrets
###############################################################################
# Generate random password
[group('secrets')]
@passwd-generate:
    pwgen -s 12 1

# Update secrets SOPS
[group('secrets')]
@secret-update FILE:
    sops updatekeys {{ FILE }}

[group('secrets')]
@init-git-crypt-secrefiles HOST:
    mkdir -p configuration/hosts/{{HOST}}/secretfiles/
    echo "* filter=git-crypt diff=git-crypt" > configuration/hosts/{{HOST}}/secretfiles/.gitattributes
    echo ".gitattributes !filter !diff" >> configuration/hosts/{{HOST}}/secretfiles/.gitattributes

# List encrypted file with git-crypt
[group('secrets')]
@file-encryption-list:
    git-crypt status | grep -v "not encrypted"

[group('certificate')]
@init-ca DOMAIN HOST:
    #!/usr/bin/env bash
    just init-git-crypt-secrefiles {{HOST}}
    export STEPPATH="configuration/hosts/{{HOST}}/secretfiles"

    step ca init \
    --name "Homelab CA" \
    --dns "localhost" \
    --address ":443" \
    --provisioner "admin@{{DOMAIN}}" \
    --deployment-type standalone

# Show installed packages
[group('flake')]
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
