# #########################################################
# NIXOS (hosts)
##########################################################
{ inputs, config, pkgs, lib, ... }: {
  imports = [
    # Host and hardware configuration
    ./hardware-configuration.nix
    ./disks.nix
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    ../../nix/nixos/features/system/containers.nix

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
  ];

  ####################################
  # Boot
  ####################################

  boot = {
    kernelParams = [ "mem_sleep_default=deep" ];
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

    # Network
    kernel = {
      sysctl = {
        # Forward on all ipv4 interfaces.
        "net.ipv4.conf.all.forwarding" = true;
      };
    };
  };

  # xorg
  # videoDrivers = [ "intel" "i965" "nvidia" ];

  ####################################
  # host profile
  ####################################
  hostprofile = { nproc = 8; };

  virtualisation.docker.storageDriver = "btrfs";

  ####################################
  # Hardware
  ####################################

  # Pulseaudio
  hardware.pulseaudio = {
    enable = true;
    support32Bit =
      true; # # If compatibility with 32-bit applications is desired
    #extraConfig = "load-module module-combine-sink";
  };

  ####################################
  # Networking
  ####################################

  networking = {
    enableIPv6 = false;
    hostName = "hype16";
    useDHCP = false;

    # Define VLANs
    vlans = {
      vlandmz = {
        id = 32;
        interface = "enp1s0"; # tagged
      };
      vlanadm = {
        id = 240;
        interface = "enp1s0"; # tagged
      };
    };

    # Create interfaces
    interfaces = {
      brlan = {
        ipv4.addresses = [{
          address = "192.168.254.16";
          prefixLength = 24;
        }];
      };

      bradm = {
        ipv4.addresses = [{
          address = "192.168.240.16";
          prefixLength = 24;
        }];
      };

      brdmz = {
        ipv4.addresses = [{
          address = "192.168.32.16";
          prefixLength = 24;
        }];
      };
    };

    # Create bridges
    bridges = {
      # untagged
      "brlan" = { interfaces = [ "enp1s0" ]; };
      "bradm" = { interfaces = [ "vlanadm" ]; };
      "brdmz" = { interfaces = [ "vlandmz" ]; };
    };

    # Define default gateway and nameservers
    defaultGateway = "192.168.254.254";
    nameservers = [ "89.2.0.1" "89.2.0.2" ];
  };

  ####################################
  # Incus hypervisor
  ####################################

  networking.nftables.enable = true;

  networking.firewall = {
    # logReversePathDrops = true;
    # logRefusedPackets = true;
    # logRefusedConnections = true;
    # logRefusedUnicastsOnly = true;

    interfaces = {
      brdmz = {
        allowedTCPPorts = [ 53 67 ];
        allowedUDPPorts = [ 53 67 ];
      };

    };

    # Forward
    # filterForward = true;
    # extraForwardRules = "iifname brdmz oifname brdmz accept";
    extraInputRules = "iifname brdmz accept";
    # "iifname brdmz ip saddr 192.168.254.0/24 ip daddr 192.168.253.0/24 accept";
  };

  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    preseed = {
      profiles = [
        {
          name = "default";
          description = "Default profile";
          devices = {
            eth0 = {
              name = "eth0";
              type = "nic";
              nictype = "bridged";
              parent = "brlan";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
        }
        {
          name = "lan";
          description = "LAN profile";
          devices = {
            eth0 = {
              name = "eth0";
              type = "nic";
              nictype = "bridged";
              parent = "brlan";
            };
          };
        }
        {
          name = "dmz";
          description = "DMZ profile";
          devices = {
            eth1 = {
              name = "eth1";
              type = "nic";
              nictype = "bridged";
              parent = "brdmz";
            };
          };
        }
      ];
      storage_pools = [{
        config = { source = "/var/lib/incus/storage-pools/default"; };
        driver = "dir";
        name = "default";
      }];
    };
  };

  ####################################
  # Storage
  ####################################
  systemd.tmpfiles.rules = [
    # trilium app
    "d /data/incus/trilium/var_lib_trilium 0750 root root -"
  ];

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
