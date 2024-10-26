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
    ../../nix/modules/nixos/host.nix

    # homelab modules
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
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
  };

  # xorg
  # videoDrivers = [ "intel" "i965" "nvidia" ];

  ####################################
  # host profile
  ####################################
  hostprofile = {
    nproc = 8;
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

  networking.hostName = "hypea";
  networking.useDHCP = lib.mkDefault true;

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };


  ####################################
  # Incus hypervisor
  ####################################

  networking.nftables.enable = true;

  networking.firewall.interfaces.incusbr0.allowedTCPPorts = [
    53
    67
  ];
  networking.firewall.interfaces.incusbr0.allowedUDPPorts = [
    53
    67
  ];

  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      networks = [
        {
          config = {
            "ipv4.address" = "192.168.254.0/24";
            "ipv4.nat" = "true";
            "ipv4.dhcp" = "false";
          };
          name = "incus-lan";
          type = "bridge";
        }
      ];
      profiles = [
        {
          devices = {
            eth0 = {
              name = "eth0";
              network = "incus-lan";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
          name = "default";
        }
      ];
      storage_pools = [
        {
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
          driver = "dir";
          name = "default";
        }
      ];
    };
  };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
