# #########################################################
# NIXOS (hosts)
##########################################################
{ lib, config, ... }:
let
  netlan = "254";
  netadm = "240";
  netdmz = "32";

  lan_address = "192.168.${netlan}.16";
  adm_address = "192.168.${netadm}.16";
  dmz_address = "192.168.${netdmz}.16";

in
{
  imports = [
    # Host and hardware configuration
    ./hardware-configuration.nix
    ./disks.nix
    ../../nix/modules/nixos/host.nix

    # Users
    ../root.nix
    ../badele.nix

    # Commons
    ../../nix/modules/nixos/homelab
    ../../nix/nixos/features/commons
    # ../../nix/nixos/features/system/containers.nix

    # Virtualisation
    # ../../nix/nixos/features/virtualisation/podman.nix
    # ../../nix/nixos/features/virtualisation/docker.nix

    # Services
    # ../../nix/nixos/services/crowdsec.nix
    ../../nix/nixos/services/fail2ban.nix
    (import ../../nix/nixos/services/traefik.nix {
      inherit lib config lan_address adm_address dmz_address;
    })

    # Containers
    ../../nix/nixos/containers/adguard.nix
    ../../nix/nixos/containers/homepage.nix

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.roles> sectionn from `homelab.json` file
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

  # Allow forward
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # virtualisation.vswitch = {
  #   enable = false;
  #   # don't reset the Open vSwitch database on reboot
  #   resetOnStart = false;
  # };

  networking = {
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

    # vswitches = {
    # br-lan = { interfaces = { enp1s0 = { }; }; };
    # br-adm = {
    #   interfaces = {
    #     vlan-adm = { };
    #     ve-adguard = { };
    #     ve-homepage = { };
    #   };
    # };
    # br-dmz = { interfaces = { vlan-dmz = { }; }; };
    # };

    # bridges = {
    #   br-lan = { interfaces = [ "enp1s0" ]; };
    #   br-adm = { interfaces = [ "vlan-adm" ]; };
    #   br-dmz = { interfaces = [ "vlan-dmz" ]; };
    # };

    # Create interfaces
    interfaces = {
      enp1s0 = {
        ipv4 = {
          addresses = [{
            address = "192.168.${netlan}.16";
            prefixLength = 24;
          }];
          # routes = [{
          #   address = "0.0.0.0";
          #   prefixLength = 0;
          #   via = "192.168.${netlan}.254";
          #   options = { metric = "100"; };
          # }];
        };
      };

      vlan-adm = {
        ipv4 = {
          addresses = [{
            address = "192.168.${netadm}.16";
            prefixLength = 24;
          }];
          # routes = [{
          #   address = "0.0.0.0";
          #   prefixLength = 0;
          #   via = "192.168.${netadm}.254";
          #   options = { metric = "100"; };
          # }];
        };
      };

      vlan-dmz = {
        ipv4 = {
          addresses = [{
            address = "192.168.${netdmz}.16";
            prefixLength = 24;
          }];
          # routes = [{
          #   address = "0.0.0.0";
          #   prefixLength = 0;
          #   via = "192.168.${netdmz}.254";
          #   options = { metric = "100"; };
          # }];
        };
      };
    };

    # Define default gateway and nameservers
    defaultGateway = "192.168.32.254";
    # nameservers = [ "89.2.0.1" "89.2.0.2" ];
    nameservers = [ "192.168.${netlan}.254" ];

    # Firewall
    firewall = {
      # Allow configure firewall with allowedTCPPorts & allowedUDPPorts values
      enable = false;
      # filterForward = true;
      # checkReversePath = "loose";

      # Logs
      # logReversePathDrops = true;
      # logRefusedPackets = true;
      # logRefusedConnections = true;
      # logRefusedUnicastsOnly = true;

      # extraInputRules = ''
      #   # LAN to traefik (on hypervisor)
      #   iifname enp1s0 ip saddr 192.168.254.0/24 ip daddr ${lan_address}/24 tcp dport {80, 443} accept comment "lan to traefik"
      #   iifname vlan-adm ip saddr 192.168.254.0/24 ip daddr ${adm_address}/24 tcp dport {80, 443} accept comment "adm to traefik"
      #   iifname vlan-dmz ip saddr 192.168.254.0/24 ip daddr ${dmz_address}/24 tcp dport {80, 443} accept comment "dmz to traefik"
      # '';
    };

    # https://wiki.nftables.org/wiki-nftables/index.php/Main_Page
    nftables = {
      enable = true;
      ruleset = ''
          table inet router {

        	set temp-ports {
        		type inet_proto . inet_service
        		flags interval
        		auto-merge
        		comment "Temporarily opened ports"
        	}

                # Reverse path filter
        	chain rpfilter {
        		type filter hook prerouting priority mangle + 10; policy drop;
        		meta nfproto ipv4 udp sport . udp dport { 68 . 67, 67 . 68 } accept comment "DHCPv4 client/server"
        		fib saddr . mark oif exists accept
        		jump rpfilter-allow
        	}

        	chain rpfilter-allow {
        	}

                # Input
        	chain input {
        		type filter hook input priority filter; policy drop;
                        iifname "lo" log prefix "ALLOW LO INPUT" accept comment "trusted interfaces"
        		ct state vmap { invalid : drop, established : accept, related : accept, new : jump input-allow, untracked : jump input-allow }
        		tcp flags & (fin | syn | rst | ack) == syn log prefix "refused connection: " level info
        	}

        	chain input-allow {
        		tcp dport 22 accept

        		meta l4proto . th dport @temp-ports accept

                        icmp type echo-request accept comment "allow ping"

                        # Mikrotik Neighbors discovery
                        udp dport 5678 accept comment "Mikrotik Neighbors discovery"

                        # Internet to DMZ
                        iifname vlan-dmz ip daddr 192.168.32.16 tcp dport {80, 443} accept comment "internet to DMZ traefik"

                        # LAN To traefik service
                        iifname enp1s0   ip saddr 192.168.${netlan}.0/24 ip daddr ${lan_address}/24 tcp dport {80, 443} accept comment "lan to traefik"
                        iifname vlan-adm ip saddr 192.168.${netlan}.0/24 ip daddr ${adm_address}/24 tcp dport {80, 443} accept comment "adm to traefik"
                        iifname vlan-dmz ip saddr 192.168.${netlan}.0/24 ip daddr ${dmz_address}/24 tcp dport {80, 443} accept comment "dmz to traefik"

                        log prefix "Blocked INPUT: " flags all drop
        	}

                chain output {
                        type filter hook output priority filter ; policy drop;

        		ct state vmap { invalid : drop, established : accept, related : accept, new : jump output-allow, untracked : jump output-allow }
                }

                chain output-allow {
                        udp dport  53 accept comment "DNS request"
                        udp dport 123 accept comment "NTP request"
                        icmp type echo-request accept comment "allow ping"

                        # crowdsec
                        oifname lo ip daddr 127.0.0.1 tcp dport 8080 accept comment "crowdsec API"
                        oifname lo ip daddr 127.0.0.1 tcp dport 6060 accept comment "crowdsec API"

                        oifname vlan-dmz tcp dport {80, 443} accept comment "hype16 to HTTP/HTTPS"
                        oifname ve-adguard ip saddr 192.168.240.16 ip daddr 192.168.241.1 tcp dport 3000 accept comment "traefik to adguard"
                        oifname ve-homepage ip saddr 192.168.240.16 ip daddr 192.168.241.2 tcp dport 8082 accept comment "traefik to homepage"

                        log prefix "Blocked OUTPUT: " flags all drop
                }

        	chain forward {
        		type filter hook forward priority filter; policy drop;
        		ct state vmap { invalid : drop, established : accept, related : accept, new : jump forward-allow, untracked : jump forward-allow }

                        log prefix "Blocked FORWARD: " flags all drop
        	}

        	chain forward-allow {
        		ct status dnat accept comment "allow port forward"

                        iifname ve-homepage oifname enp1s0 udp dport 53
        	}
        }
      '';
    };
  };

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
