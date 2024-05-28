##########################################################
# NIXOS (hosts)
##########################################################
{ inputs
, config
, pkgs
, lib
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    #inputs.hardware.nixosModules.dell-xps-15-9560
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../demo.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    # ../../nix/nixos/features/system/containers.nix
    # ../../nix/nixos/features/system/virtualisation.nix

    # i3
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix

    # Gnome
    # ../../nix/nixos/features/desktop/wm/xorg/gdm.nix # Gnome
  ];

  ####################################
  # Boot
  ####################################


  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
    ];
    blacklistedKernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "btrfs" ];

    # Grub EFI boot loader
    loader = {
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiInstallAsRemovable = true;
        efiSupport = true;
        useOSProber = true;
      };
    };

    # Qemu support
    initrd = {
      availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
      kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
      postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable)
        ''
          # Set the system time from the hardware clock to work around a
          # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
          # to the *boot time* of the host).
          hwclock -s
        '';
    };
  };

  # xorg
  # videoDrivers = [ "intel" "i965" "nvidia" ];

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 12;
    autologin = {
      user = "demo";
      session = "none+i3";
    };
  };

  ####################################
  # Hardware
  ####################################

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true; ## If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  networking.hostName = "demovm";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = {
    dconf.enable = true;
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
