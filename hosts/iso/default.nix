##########################################################
# NIXOS (hosts)
##########################################################
{ inputs
, config
, pkgs
, lib
, ...
}:
let
  installpassword = "nixosusb";
  sshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== cardno:18_150_451";
in
{
  imports = [
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  # Managed by networkmanager
  networking.wireless.enable = false;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
  };

  ##############################################################################
  # User definition
  ##############################################################################
  users = {
    users = {
      root =
        {
          initialPassword = installpassword;
          openssh.authorizedKeys.keys = [
            sshkey
          ];
        };

      nixos = {
        initialPassword = installpassword;
        openssh.authorizedKeys.keys = [
          sshkey
        ];
      };
    };
  };

  # services = {
  #   openssh.settings.PermitRootLogin = lib.mkForce "yes";
  # };
  # systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.nixos.extraGroups = [
    "wheel"
    "video"
    "audio"
    "networkmanager"
    "libvirtd"
    "kvm"
    "docker"
    "git"
  ];


  ##############################################################################
  # Packages
  ##############################################################################

  # Disable gnome tour
  environment.gnome.excludePackages =
    (with pkgs; [ gnome-tour ]);

  powerManagement.enable = lib.mkForce false;
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.session]
    idle-delay=0
    
    [org.gnome.settings-daemon.plugins.power]
    sleep-inactive-ac-type='nothing'
    
    [org.gnome.desktop.interface]
    color-scheme='prefer-dark'
  '';

  services.getty.helpLine = ''
                            ███╗   ██╗██╗██╗  ██╗                             
                            ████╗  ██║██║╚██╗██╔╝                             
                            ██╔██╗ ██║██║ ╚███╔╝                              
                            ██║╚██╗██║██║ ██╔██╗                              
                            ██║ ╚████║██║██╔╝ ██╗                             
                            ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝                             
                                                                      
            ██╗  ██╗ ██████╗ ███╗   ███╗███████╗██╗      █████╗ ██████╗       
            ██║  ██║██╔═══██╗████╗ ████║██╔════╝██║     ██╔══██╗██╔══██╗      
            ███████║██║   ██║██╔████╔██║█████╗  ██║     ███████║██████╔╝      
            ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║██╔══██╗      
            ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗███████╗██║  ██║██████╔╝      
            ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝       
                                                                      
        ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
        ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
        ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
        ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
        ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
        ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
                         (c) 2024 github.com/badele/nix-homelab

    Tools:
    - nmtui : Network Manager TUI

  '';

  # Just git gum :)
  environment.systemPackages = with pkgs;
    [
      just
      git
      gum

      btrfs-progs
      rsync

      (
        writeShellScriptBin "installer"
          ''
            #!/usr/bin/env bash
            set -euo pipefail

            if [ ! -d "$HOME/nix-homelab/.git" ]; then
              git clone -q https://github.com/badele/nix-homelab.git "$HOME/nix-homelab"
            fi

            gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Chose the $(gum style --foreground 212 'host') to install ."

            TARGET_HOST=$(ls -1 $HOME/nix-homelab/hosts/*/default.nix | sed 's|.*/hosts/||g' | cut -d'/' -f1 | grep -v iso | gum choose)

            if [ -e "$HOME/nix-homelab/hosts/$TARGET_HOST/disks.nix" ]; then
              gum confirm  --default=false \
              "🚨 🚨 🚨 WARNING!!!! This will ERASE ALL DATA on the disk $TARGET_HOST !!! 🚨 🚨 🚨 Do you want to continue ?"

              echo "Partitioning Disks"
              sudo nix run github:nix-community/disko \
              --extra-experimental-features "nix-command flakes" \
              --no-write-lock-file \
              -- \
              --mode zap_create_mount \
              "$HOME/nix-homelab/hosts/$TARGET_HOST/disks.nix"
            fi
            sudo nixos-install --flake "$HOME/nix-homelab#$TARGET_HOST"
          ''
      )
    ];
}
