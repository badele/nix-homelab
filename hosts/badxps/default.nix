# #########################################################
# NIXOS (hosts)
##########################################################
{ inputs, config, pkgs, lib, ... }:
let
  wireguard_endpoint = "84.234.31.97:54321";
  wireguard_private_ips = [ "10.123.0.2/24" ];
  wireguard_public_key = "LQX7VSva7CZJmjmbGrFmG+37bS0PtTgy9Q6/15lIh08=";

in
{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-9570-intel
    ./hardware-configuration.nix

    # homelab modules
    ../../nix/modules/nixos/host.nix

    # Users account
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    ../../nix/nixos/features/system/containers.nix

    ../../nix/nixos/features/virtualisation/incus.nix
    ../../nix/nixos/features/virtualisation/libvirt.nix

    # Desktop
    ../../nix/nixos/features/system/bluetooth.nix
    ../../nix/nixos/features/desktop/wm/xorg/lightdm.nix

    # # Roles
    # ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
  ];

  ####################################
  # Boot
  ####################################

  # Docker
  virtualisation.docker.storageDriver = "zfs";

  nixpkgs.config = {
    # allowBroken = true;
    # nvidia.acceptLicense = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_6;
    kernelParams = [
      "i915.force_probe=3e9b"
      "mem_sleep_default=deep"
      "acpi_osi=!"
      ''acpi_osi="Windows 2015"''
      "acpi_backlight=vendor"
    ];

    blacklistedKernelModules = [ "nouveau" "bbswitch" ];

    kernelModules = [ "kvm-intel" ];
    #extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];
    supportedFilesystems = [ "zfs" "ntfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      extraPools = [ "zroot" ];
    };

    # EFI boot loader
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
  };

  # xorg
  # services.xserver.videoDrivers = [ "intel" "i965" "nvidia" ];
  services.xserver.videoDrivers = [ "modesetting" ];
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.opengl.enable = true;
  #hardware.nvidia.package = boot.kernelPackages.nvidiaPackages.stable;
  #hardware.nvidia.modesetting.enable = true;

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 12;
    autologin = {
      user = "badele";
      session = "none+i3";
    };
  };

  ####################################
  # Hardware
  ####################################

  # Enable OpenGL acceleration
  hardware.graphics.enable = true;

  # intel
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs;
      [
        vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
      ];
  };

  # Nvidia
  # hardware.nvidia = {
  #   open = false;
  #   # modesetting.enable = true;
  #   # powerManagement.enable = false;
  #   # powerManagement.finegrained = false;
  #   # nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.production; # 550.90.07
  #   #
  #   # # sudo lshw -c display
  #   # # Convert the hex result to decimal bus PCI, ex: 0e:00:00 to 14:0:0
  #   # prime = {
  #   #   intelBusId = "PCI:0:2:0";
  #   #   nvidiaBusId = "PCI:1:0:0";
  #   # };
  # };

  # hardware.bumblebee.enable = true;
  # hardware.bumblebee.pmMethod = "none"; # Needs nixos-unstable
  # hardware.nvidia.optimus_prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  # Pulseaudio
  services.pipewire.enable = false;
  hardware.pulseaudio = {
    enable = true;
    support32Bit =
      true; # # If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  ####################################
  # Network
  ####################################

  networking.hostName = "badxps";
  networking.useDHCP = lib.mkDefault true;

  networking.wireguard = {
    enable = true;
    interfaces = {
      wg-cab1e = {
        ips = wireguard_private_ips;
        privateKeyFile = config.sops.secrets."wireguard/private_peer".path;

        postSetup = ''
          # ${pkgs.iproute2}/bin/ip route add 84.234.31.97 via 192.168.254.254 dev wlp59s0
          ${pkgs.iproute2}/bin/ip route add default via 10.123.0.2
        '';

        peers = [{
          publicKey = wireguard_public_key;
          allowedIPs = [ "0.0.0.0/0" ]; # Tout le trafic passe par le VPN
          endpoint = wireguard_endpoint;
          persistentKeepalive = 25; # Permet de maintenir la connexion active
        }];
      };
    };
  };

  # networking.nameservers = [ "1.1.1.1" ];

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { dconf.enable = true; };
  environment.systemPackages = with pkgs; [ ];

  ####################################
  # Secrets
  ####################################

  sops.secrets = {
    "spotify/user" = {
      mode = "0400";
      owner = config.users.users.badele.name;
    };

    "spotify/password" = {
      mode = "0400";
      owner = config.users.users.badele.name;
    };

    "wireguard/private_peer" = { sopsFile = ../../hosts/badxps/secrets.yml; };
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
