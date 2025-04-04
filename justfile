#!/usr/bin/env just -f

set export

SSHPASS := "nixosusb"

# This help
# Help it showed if just is called without arguments
@help:
    just -l -u | column -s '#' -t | sed 's/[ \t]*$//'

###############################################################################
# Pre-commit
###############################################################################

# Setup pre-commit
precommit-install:
    #!/usr/bin/env bash
    test ! -f .git/hooks/pre-commit && pre-commit install || true

# Update pre-commit
@precommit-update:
    pre-commit autoupdate

# precommit check
@precommit-check:
    pre-commit run --all-files

###############################################################################
# Documentation
###############################################################################

# Update documentation
@doc-update FAKEFILENAME:
    ./.pre-commit-scripts/updatedoc.ts

# Lint the project
@lint:
    pre-commit run --all-files

###############################################################################
# Documentation
###############################################################################

# Repl the project
@debug-repl:
    nix repl --extra-experimental-features repl-flake .#

###############################################################################
# Flake
###############################################################################

# Show flake metadata
@flake-metadata:
    nix flake metadata

# Update the flake
@flake-update:
    nix flake update

# Sync the nix registry with the current running nix version
@flake-sync-registry:
    nix registry pin nixpkgs github:NixOS/nixpkgs/$(nix flake metadata --json | jq -r '.locks.nodes."nixpkgs".locked.rev')
    # nix flake metadata --json | jq -r '.locks.nodes."nixpkgs".locked.rev'
    # nix flake metadata --json | jq -r '.locks.nodes."home-manager".locked.rev'

# Check the nix homelab configuration
@flake-check:
    nix flake check

###############################################################################
# NIXOS installer
###############################################################################

# Generate random password
@passwd-generate:
    pwgen -s 12 1

# Update secrets SOPS
@secret-update FILE:
    sops updatekeys {{ FILE }}

[private]
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
nixos-init-host host: (nixos-init-root-pass host) (nixos-init-ssh-host host)

# Install new <hostname> to <target>:<port> system wide
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
@nixos-garbage:
    sudo nix-collect-garbage -d

# Nixos build local host
@nixos-build hostname="" options="":
    just nixos-command build {{ hostname }} {{ options }}

# Install new <hostname> to <target>:<port> system wide
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

# Update NixOS on local host
@nixos-update options="":
    just nixos-command switch "" {{ options }}

# Update on remote host
@nixos-remote-update hostname targetip options="":
    just nixos-command switch {{hostname}} "--target-host root@{{ targetip }}" {{ options }}

[private]
home-command action:
    home-manager {{action}} --option accept-flake-config true --flake .

# Home build for local user
@home-build:
    just home-command build

# Home deploy local user
@home-deploy:
    just home-command switch

###############################################################################
# ISO & Demo
###############################################################################

# Build NixOS ISO image
@iso-build:
    nix build '.#nixosConfigurations.iso.config.system.build.isoImage'

# Init demo credentials
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

[private]
@demo-create-disk:
    [ -e disk-demo.raw ] || qemu-img create disk-demo.raw 20G

# Start NixOS demo from ISO image
@demo-start: demo-create-disk
    qemu-system-x86_64 -enable-kvm -smp 2 -m 4096 --bios $UEFI_FILE -device virtio-vga -net nic,model=virtio-net-pci -net user,hostfwd=tcp::2222-:22 -drive file=disk-demo.raw,format=raw -cdrom result/iso/nixos-*.iso &

# (type ESC for select boot device)
# Test NixOS installation deployment on qemu virutal machine
@demo-qemu-nixos-install: demo-init-credentials demo-start
    ssh-keygen -R "[127.0.0.1]:2222"
    just demo-nixos-install demovm 127.0.0.1 2222

# (type ESC for select boot device)
# Test NixOS update deployment on qemu virutal machine
@demo-qemu-nixos-update: demo-start
    ssh-keygen -R "[127.0.0.1]:2222"
    # Disable --fast (if you have error: cached failure of attribute)
    # Disable --fallback (if you have error: cannot build derivation)
    NIX_SSHOPTS="-l root -p 2222 -o StrictHostKeychecking=no" nixos-rebuild switch --fallback --show-trace --option accept-flake-config true --target-host 127.0.0.1 --flake .#demovm

# Stop demo vm test
@demo-stop:
    pkill qemu

# Clean demo vm test
@demo-clean:
    rm -f disk-demo.raw

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
