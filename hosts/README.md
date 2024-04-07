# Host installation

<!--toc:start-->

- [Host installation](#host-installation)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Update](#update)

<!--toc:end-->

## Requirements

- Computer with NixOS
- Customised a NixOS ISO installer `just iso-build` (see
  `./hosts/iso/default.nix` for some options)
  - Passwordless SSH public key
  - Users password
  - Keyboard layout
  - Your customised scripts
- A passwordstore configured `PASSWORD_STORE_DIR`

## Installation

- From new host
  - launch USB installer

- from nix-homelab project folder (generally user desktop)
  - init new host with `just nixos-init-host <HOSTNAME>` (generate a SSH keys
    and age key), store de private key on `nix-homelab/hosts/<HOSTNAME>/*`
    passowrdstore
  - Create a new host configuration in `homelab.json`
  - Add the content generated age key (`./hosts/<HOSTNAME>/ssh-to-age.txt`) in
    `hosts` section on the `.sops.yaml`
  - Create new host section on `flake.nix`
    - in `nixosConfigurations`
    - in `homeConfigurations`
  - Update credentials for new host
    - Edit `sops ./hosts/<HOSTNAME>/secrets.yml`
      - Add root passwd
        - `just passwd-generate`
        - `pass show nix-homelab/hosts/<HOSTNAME>/accounts/root | mkpasswd -m sha-512 -s`
    - Update host credentials for host key
      `just secret-update hosts/<HOSTNAME>/secrets.yml`
  - Configure NixOS host
    - `./hosts/<HOSTNAME>/default.nix`
    - `./hosts/<HOSTNAME>/disks.nix`
    - `./hosts/<HOSTNAME>/hardware-configuration.nix`
  - Deploy system wide environment
    - `just nixos-install <HOSTNAME> <TARGETIP> <PORT=22>` or
      `just iso-test-install` for testing in vm-test on qemu
  - Deploy user environment (logon on new host)
    - `ghq get git@github.com:badele/nix-homelab.git`
    - `cd ~/ghq/github.com/badele/nix-homelab/`
    - `nix develop`
    - `just home-deploy`

## Update
