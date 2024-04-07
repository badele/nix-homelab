#!/usr/bin/env just -f

# This help
# Help it showed if just is called without arguments
@help:
    just -lu | column -s '#' -t | sed -i 's/[ \t]*$//'

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
    ./updatedoc.ts

# Lint the project
@lint:
    pre-commit run --all-files

# Repl the project
@repl:
    nix repl --extra-experimental-features repl-flake .#

###############################################################################
# NIXOS installer
###############################################################################

# Generate random password
@passwd-generate:
    pwgen -s 12 1

# Update secrets SOPS
@secret-update FILE:
    sops updatekeys {{ FILE }}

# Init nixos host if not exists
nixos-init-host host:
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
        cat /tmp/nix-homelab/ssh_host_rsa_key | pass insert -m nix-homelab/hosts/{{host}}/ssh_host_rsa_key
        cat /tmp/nix-homelab/ssh_host_ed25519_key | pass insert -m nix-homelab/hosts/{{host}}/ssh_host_ed25519_key

        # Copy ssh keys to host configuration
        cp /tmp/nix-homelab/ssh_host_rsa_key.pub ./hosts/{{host}}
        cp /tmp/nix-homelab/ssh_host_ed25519_key.pub ./hosts/{{host}}

        # Create age key from host ssh key
        ssh-to-age -i ./hosts/{{host}}/ssh_host_ed25519_key.pub -o ./hosts/{{host}}/ssh-to-age.txt

        # Generate root password
        just passwd-generate | pass insert -m nix-homelab/hosts/{{host}}/accounts/root
    fi

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
    pass nix-homelab/hosts/vm-test/ssh_host_ed25519_key > "/tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key"
    chmod 600 "/tmp/nix-homelab/etc/ssh/ssh_host_ed25519_key"
    nix run github:nix-community/nixos-anywhere -- --extra-files /tmp/nix-homelab -p {{port}} --flake .#{{hostname}} root@{{targetip}}

[private]
nixos-command action hostname="" options="":
    echo sudo nixos-rebuild {{ action }} {{ options }} --fast --option accept-flake-config true --flake .#{{ hostname }}

# Nixos build local host
@nixos-build hostname="" options="":
    just nixos-command build {{ hostname }} {{ options }}

# Deploy NixOS on local host
@nixos-deploy hostname="" options="":
    just nixos-command switch {{ hostname }} {{ options }}

# Deploy NixOS on remote host
@nixos-remote-deploy hostname targetip:
    just nixos-command switch {{ hostname }} "--target-host root@{ targetip }}"

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
# ISO
###############################################################################

# Build NixOS ISO image
@iso-build:
    nix build '.#nixosConfigurations.iso.config.system.build.isoImage'

[private]
@iso-create-disk:
    [ -e disk-iso-test.raw ] || qemu-img create disk-iso-test.raw 20G

# Start test NixOS ISO image
@iso-start: iso-create-disk
    qemu-system-x86_64 -enable-kvm -smp 2 -m 4096 --bios $UEFI_FILE -net nic,model=virtio-net-pci -net user,hostfwd=tcp::2222-:22 -drive file=disk-iso-test.raw,format=raw -cdrom result/iso/nixos-*.iso &

# Test ISO image (ESC for select boot device)
@iso-test: iso-start

# Test NixOS deployment with custom ISO image (ESC for select boot device)
@iso-test-install: iso-start
    just nixos-install vm-test localhost 2222

# Test NixOS update deployment with custom ISO image (ESC for select boot device)
iso-test-remote-deploy:
    sudo NIX_SSHOPTS="-p 2222" nixos-rebuild switch --fast --option accept-flake-config true --target-host 127.0.0.1 --flake .#vm-test

# Stop ISO vm test
@iso-stop:
    pkill qemu

# Clean ISO vm test
@iso-clean:
    rm -f disk-iso-test.raw

# Show installed packages
@packages:
    echo $PATH | tr ":" "\n" | grep -E "/nix/store" | sed -e "s/\/nix\/store\/[a-z0-9]\+\-//g" | sed -e "s/\/.*//g"
