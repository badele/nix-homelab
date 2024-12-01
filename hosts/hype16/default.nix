# #########################################################
# NIXOS (hosts)
##########################################################
{ lib, ... }: {
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
    # ../../nix/nixos/features/system/containers.nix

    # traefik
    # ../../nix/nixos/features/system/traefik.nix

    # Virtualisation
    # ../../nix/nixos/features/virtualisation/podman.nix
    # ../../nix/nixos/features/virtualisation/docker.nix
    ../../nix/nixos/services/traefik.nix
    ../../nix/nixos/containers/adguard.nix
    #
    # ../../nix/nixos/containers/homepage.nix
    # ../../nix/nixos/containers/traefik.nix
    # ../../nix/nixos/containers/nextcloud.nix

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
  # https://nixos.wiki/wiki/Systemd-networkd
  # Static network configuration

  # Allow forward
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  virtualisation.vswitch = {
    enable = true;
    # don't reset the Open vSwitch database on reboot
    resetOnStart = false;
  };

  networking =
    let
      netlan = "254";
      netadm = "240";
      netdmz = "32";
    in
    {
      hostName = "hype16";

      # Disable some features
      wireless.enable = false;
      enableIPv6 = false;
      nat.enable = false;
      useDHCP = false;

      # See     ../../nix/nixos/features/commons/networking.nix

      # Define VLANs
      vlans = {
        vlan-dmz = {
          id = 32;
          interface = "enp1s0"; # tagged
        };
        vlan-adm = {
          id = 240;
          interface = "enp1s0"; # tagged
        };
      };

      vswitches = {
        br-lan = { interfaces = { enp1s0 = { }; }; };
        br-adm = {
          interfaces = {
            vlan-adm = { };
            vb-adguard = { };
          };
        };
        br-dmz = { interfaces = { vlan-dmz = { }; }; };
      };

      # bridges = {
      #   br-lan = { interfaces = [ "enp1s0" ]; };
      #   br-adm = { interfaces = [ "vlan-adm" ]; };
      #   br-dmz = { interfaces = [ "vlan-dmz" ]; };
      # };

      # Create interfaces
      interfaces = {
        br-lan = {
          ipv4 = {
            addresses = [{
              address = "192.168.${netlan}.16";
              prefixLength = 24;
            }];
            routes = [{
              address = "0.0.0.0";
              prefixLength = 0;
              via = "192.168.${netlan}.254";
            }];

          };
        };

        br-adm = {
          ipv4 = {
            addresses = [{
              address = "192.168.${netadm}.16";
              prefixLength = 24;
            }];
            routes = [{
              address = "0.0.0.0";
              prefixLength = 0;
              via = "192.168.${netadm}.254";
            }];
          };
        };

        br-dmz = {
          ipv4 = {
            addresses = [{
              address = "192.168.${netdmz}.16";
              prefixLength = 24;
            }];
            routes = [{
              address = "0.0.0.0";
              prefixLength = 0;
              via = "192.168.${netdmz}.254";
            }];
          };
        };
      };

      # Define default gateway and nameservers
      # defaultGateway = "192.168.254.254";
      nameservers = [ "89.2.0.1" "89.2.0.2" ];

      # Firewall
      firewall = {
        # Allow configure firewall with allowedTCPPorts & allowedUDPPorts values
        enable = true;
        checkReversePath = "loose";

        # Logs
        logReversePathDrops = true;
        logRefusedPackets = true;
        logRefusedConnections = true;
        logRefusedUnicastsOnly = true;
      };

      nftables = {
        enable = true;
        ruleset = ''
          table inet filter {
            chain input {
              type filter hook input priority 0; policy drop;

              #ct state { established, related } accept comment "Allow established traffic"

              iifname { "br-lan" } accept comment "Allow lan network to access the router"
              #iifname { "br-adm" } accept comment "Allow adm network to access the router"
              iifname "lo" accept comment "Accept everything from loopback interface"

            }
            chain forward {
              type filter hook forward priority filter; policy drop;

              ct state { established, related } accept comment "Allow established back to LANs"

              # adguard
              # 23:29:47.453176 enp1s0 P   IP 192.168.254.114.51756 > 192.168.240.96.3000: Flags [S], seq 3951890633, win 64240, options [mss 1460,sackOK,TS val 273335813 ecr 0,nop,wscale 7], length 0
              # 23:29:47.453176 vlan-adm P   IP 192.168.254.114.51756 > 192.168.240.96.3000: Flags [S], seq 3951890633, win 64240, options [mss 1460,sackOK,TS val 273335813 ecr 0,nop,wscale 7], length 0
              # 23:29:47.453198 vb-adguard Out IP 192.168.254.114.51756 > 192.168.240.96.3000: Flags [S], seq 3951890633, win 64240, options [mss 1460,sackOK,TS val 273335813 ecr 0,nop,wscale 7], length 0
              # 23:29:47.453271 vb-adguard P   IP 192.168.240.96.3000 > 192.168.254.114.51756: Flags [S.], seq 2593899192, ack 3951890634, win 65160, options [mss 1460,sackOK,TS val 902428753 ecr 273335813,nop,wscale 7], length 0
              # 23:29:47.453285 br-adm In  IP 192.168.240.96.3000 > 192.168.254.114.51756: Flags [S.], seq 2593899192, ack 3951890634, win 65160, options [mss 1460,sackOK,TS val 902428753 ecr 273335813,nop,wscale 7], length 0
              # 23:29:47.453315 br-lan Out IP 192.168.240.96.3000 > 192.168.254.114.51756: Flags [S.], seq 2593899192, ack 3951890634, win 65160, options [mss 1460,sackOK,TS val 902428753 ecr 273335813,nop,wscale 7], length 0
              # 23:29:47.453320 enp1s0 Out IP 192.168.240.96.3000 > 192.168.254.114.51756: Flags [S.], seq 2593899192, ack 3951890634, win 65160, options [mss 1460,sackOK,TS val 902428753 ecr 273335813,nop,wscale 7], length 0
              iifname "br-adm" oifname "br-lan" ip saddr 192.168.${netadm}.96 tcp sport 3000 accept comment "Allow adguard"

              #iifname  "br-lan" oifname "br-lan" accept comment "Allow trusted LAN to LAN"
              #iifname  "br-lan" oifname "br-adm" accept comment "Allow trusted LAN to ADM"
              #iifname  "br-lan" oifname "br-dmz" accept comment "Allow trusted LAN to DMZ"

              log prefix "Blocked Forward: " flags all drop
            }
          }
        '';
      };
    };

  # systemd.network = let
  #   netlan = "254";
  #   netadm = "240";
  #   netdmz = "32";
  # in {
  #   enable = true;
  #   wait-online.anyInterface = true;
  #
  #   # Create VLAN and bridge interfaces
  #   # networkctl list
  #   netdevs = {
  #     # VLANs
  #     "10-vlan-adm" = {
  #       netdevConfig = {
  #         Kind = "vlan";
  #         Name = "vlan-adm";
  #       };
  #       vlanConfig.Id = 240;
  #     };
  #     "10-vlan-dmz" = {
  #       netdevConfig = {
  #         Kind = "vlan";
  #         Name = "vlan-dmz";
  #       };
  #       vlanConfig.Id = 32;
  #     };
  #
  #     # Bridges
  #     "10-br-lan" = {
  #       netdevConfig = {
  #         Kind = "bridge";
  #         Name = "br-lan";
  #       };
  #     };
  #     "10-br-adm" = {
  #       netdevConfig = {
  #         Kind = "bridge";
  #         Name = "br-adm";
  #       };
  #     };
  #     "10-br-dmz" = {
  #       netdevConfig = {
  #         Kind = "bridge";
  #         Name = "br-dmz";
  #       };
  #     };
  #   };
  #
  #   networks = {
  #     # Disable wireless
  #     "15-wlp2s0" = {
  #       matchConfig.Name = "wlp2s0";
  #       networkConfig = {
  #         DHCP = "no";
  #         LinkLocalAddressing = "no";
  #       };
  #     };
  #
  #     # VLANs tagging and connect enp1s0 to the bridge
  #     "15-enp1s0" = {
  #       matchConfig.Name = "enp1s0";
  #       linkConfig.RequiredForOnline = "enslaved";
  #       vlan = [ "vlan-adm" "vlan-dmz" ];
  #       networkConfig = {
  #         DHCP = "no";
  #         Bridge = "br-lan";
  #         LinkLocalAddressing = "no";
  #       };
  #     };
  #
  #     "20-br-lan-addr" = {
  #       matchConfig.Name = "br-lan";
  #       address = [ "192.168.${netlan}.16/24" ];
  #       routes = [{ Gateway = "192.168.${netlan}.254"; }];
  #     };
  #
  #     "20-br-adm-addr" = {
  #       matchConfig.Name = "br-adm";
  #       address = [ "192.168.${netadm}.16/24" ];
  #       routes = [{ Gateway = "192.168.${netadm}.254"; }];
  #     };
  #
  #     "20-br-dmz-addr" = {
  #       matchConfig.Name = "br-dmz";
  #       address = [ "192.168.${netdmz}.16/24" ];
  #       routes = [{ Gateway = "192.168.${netdmz}.254"; }];
  #     };
  #
  #     "20-vlan-adm" = {
  #       matchConfig.Name = "vlan-adm";
  #       linkConfig.RequiredForOnline = "enslaved";
  #       networkConfig = {
  #         DHCP = "no";
  #         Bridge = "br-adm";
  #         LinkLocalAddressing = "no";
  #       };
  #     };
  #
  #     "20-vlan-dmz" = {
  #       matchConfig.Name = "vlan-dmz";
  #       linkConfig.RequiredForOnline = "enslaved";
  #       networkConfig = {
  #         DHCP = "no";
  #         Bridge = "br-dmz";
  #         LinkLocalAddressing = "no";
  #       };
  #     };
  #   };
  # };

  ####################################
  # Incus hypervisor
  ####################################

  #
  # networking.firewall = {
  # logReversePathDrops = true;
  # logRefusedPackets = true;
  # logRefusedConnections = true;
  # logRefusedUnicastsOnly = true;

  # Forward
  # filterForward = true;
  # extraForwardRules = "iifname brdmz oifname brdmz accept";
  # extraInputRules = "iifname brdmz accept";
  # "iifname brdmz ip saddr 192.168.254.0/24 ip daddr 192.168.253.0/24 accept";
  # };

  # virtualisation.incus = {
  #   enable = true;
  #   ui.enable = true;
  #   preseed = {
  #     profiles = [
  #       {
  #         name = "default";
  #         description = "Default profile";
  #         devices = {
  #           eth0 = {
  #             name = "eth0";
  #             type = "nic";
  #             nictype = "bridged";
  #             parent = "brlan";
  #           };
  #           root = {
  #             path = "/";
  #             pool = "default";
  #             size = "35GiB";
  #             type = "disk";
  #           };
  #         };
  #       }
  #       {
  #         name = "lan";
  #         description = "LAN profile";
  #         devices = {
  #           eth0 = {
  #             name = "eth0";
  #             type = "nic";
  #             nictype = "bridged";
  #             parent = "brlan";
  #           };
  #         };
  #       }
  #       {
  #         name = "dmz";
  #         description = "DMZ profile";
  #         devices = {
  #           eth1 = {
  #             name = "eth1";
  #             type = "nic";
  #             nictype = "bridged";
  #             parent = "brdmz";
  #           };
  #         };
  #       }
  #     ];
  #     storage_pools = [{
  #       config = { source = "/var/lib/incus/storage-pools/default"; };
  #       driver = "dir";
  #       name = "default";
  #     }];
  #   };
  # };

  ####################################
  # Storage
  ####################################
  # systemd.tmpfiles.rules = [
  #   # trilium app
  #   "d /data/incus/trilium/var_lib_trilium 0750 root root -"
  # ];

  ####################################
  # Programs
  ####################################
  powerManagement.powertop.enable = true;
  programs = { };

  nixpkgs.hostPlatform.system = "x86_64-linux";
  system.stateVersion = "24.05";
}
