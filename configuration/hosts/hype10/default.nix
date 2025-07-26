# #########################################################
# NIXOS (hosts)
##########################################################
{ config, ... }:
let
  hl = config.homelab;
  nets = hl.networks;
  hostcfg = hl.currentHost;

  # Networks (VLAN) addresses
  infra_addr = hl.lib.computeNetworkHostAddress nets.infra.net hostcfg.hostIpId;
  adm_addr = hl.lib.computeNetworkHostAddress nets.adm.net hostcfg.hostIpId;
  dmz_addr = hl.lib.computeNetworkHostAddress nets.dmz.net hostcfg.hostIpId;
  # lan_addr = hl.lib.computeNetworkHostAddress nets.lan.net hostcfg.hostIpId;
  lan_addr = "192.168.254.10";
in {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix

    # Retrieve homelab hosts information
    ../hosts-information.nix

    # Modules
    ../../../nix/modules/nixos/homelab

    # Users account
    ../root.nix
    ../badele.nix

    # Commons
    ../../../nix/nixos/features/commons
    ../../../nix/nixos/features/system/containers.nix

    # Virtualisation
    # ../../nix/nixos/features/virtualisation/podman.nix
    # ../../nix/nixos/features/virtualisation/docker.nix

    # Services
    # ../../nix/nixos/services/crowdsec.nix
    # ../../../nix/nixos/services/fail2ban.nix
    # (import ../../../nix/nixos/services/traefik.nix {
    #   inherit lib config lan_addr adm_addr dmz_addr;
    # })

    # Containers
    # ../../nix/nixos/containers/adguard.nix
    # ../../nix/nixos/containers/homepage.nix

    # Roles
    ../../../nix/nixos/roles # Automatically load service from <host.roles> sectionn from `homelab.json` file
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
  # environment.systemPackages = with pkgs; [ nftables ];

  networking = {
    hostName = "hype10";

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
        interface = hostcfg.params.net.interface; # tagged
      };
      vlan-infra = {
        id = hostcfg.params.net.vlans.infra.id;
        interface = hostcfg.params.net.interface; # tagged
      };
      vlan-adm = {
        id = hostcfg.params.net.vlans.adm.id;
        interface = hostcfg.params.net.interface; # tagged
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
      "${hostcfg.params.net.interface}" = {
        ipv4 = {
          addresses = [{
            address = lan_addr;
            prefixLength = 24;
          }];
          # routes = [{
          #   address = "0.0.0.0";
          #   prefixLength = 0;
          #   via = "192.168.${toString netlan}.254";
          #   options = { metric = "100"; };
          # }];
        };
      };

      vlan-infra = {
        ipv4 = {
          addresses = [{
            address = infra_addr;
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

      vlan-adm = {
        ipv4 = {
          addresses = [{
            address = adm_addr;
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
            address = dmz_addr;
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
    nameservers = [ "192.168.${toString nets.lan.vlanId}.254" ];

    # Firewall
    # firewall = {
    # Allow configure firewall with allowedTCPPorts & allowedUDPPorts values
    # enable = false;
    # filterForward = true;
    # checkReversePath = "loose";

    # Logs
    # logReversePathDrops = true;
    # logRefusedPackets = true;
    # logRefusedConnections = true;
    # logRefusedUnicastsOnly = true;

    # extraInputRules = ''
    #   # LAN to traefik (on hypervisor)
    #   iifname enp1s0 ip saddr 192.168.254.0/24 ip daddr ${lan_addr}/24 tcp dport {80, 443} accept comment "lan to traefik"
    #   iifname vlan-adm ip saddr 192.168.254.0/24 ip daddr ${adm_addr}/24 tcp dport {80, 443} accept comment "adm to traefik"
    #   iifname vlan-dmz ip saddr 192.168.254.0/24 ip daddr ${dmz_addr}/24 tcp dport {80, 443} accept comment "dmz to traefik"
    # '';
    # };

    firewall = {
      # package = pkgs.iptables-nftables-compat;
      enable = true;
      logRefusedPackets = true;
      logReversePathDrops = true;
      logRefusedConnections = true;
    };

    # Use nftables instead of iptables
    nftables.enable = true;

    # https://wiki.nftables.org/wiki-nftables/index.php/Main_Page
    # nftables = {
    #   enable = true;
    #   ruleset = ''
    #       table inet router {
    #
    #     	set temp-ports {
    #     		type inet_proto . inet_service
    #     		flags interval
    #     		auto-merge
    #     		comment "Temporarily opened ports"
    #     	}
    #
    #             # Reverse path filter
    #     	chain rpfilter {
    #     		type filter hook prerouting priority mangle + 10; policy drop;
    #     		meta nfproto ipv4 udp sport . udp dport { 68 . 67, 67 . 68 } accept comment "DHCPv4 client/server"
    #     		fib saddr . mark oif exists accept
    #     		jump rpfilter-allow
    #     	}
    #
    #     	chain rpfilter-allow {
    #     	}
    #
    #             # Input
    #     	chain input {
    #     		type filter hook input priority filter; policy drop;
    #                     iifname "lo" log prefix "ALLOW LO INPUT" accept comment "trusted interfaces"
    #     		ct state vmap { invalid : drop, established : accept, related : accept, new : jump input-allow, untracked : jump input-allow }
    #     		tcp flags & (fin | syn | rst | ack) == syn log prefix "refused connection: " level info
    #     	}
    #
    #     	chain input-allow {
    #     		tcp dport 22 accept
    #
    #     		meta l4proto . th dport @temp-ports accept
    #
    #                     icmp type echo-request accept comment "allow ping"
    #
    #                     # Mikrotik Neighbors discovery
    #                     udp dport 5678 accept comment "Mikrotik Neighbors discovery"
    #
    #                     # Internet to DMZ
    #                     iifname vlan-dmz ip daddr 192.168.32.16 tcp dport {80, 443} accept comment "internet to DMZ traefik"
    #
    #                     # LAN To traefik service
    #                     iifname enp1s0   ip saddr 192.168.${
    #                       toString netlan
    #                     }.0/24 ip daddr ${lan_addr}/24 tcp dport {80, 443} accept comment "lan to traefik"
    #                     iifname vlan-adm ip saddr 192.168.${
    #                       toString netlan
    #                     }.0/24 ip daddr ${adm_addr}/24 tcp dport {80, 443} accept comment "adm to traefik"
    #                     iifname vlan-dmz ip saddr 192.168.${
    #                       toString netlan
    #                     }.0/24 ip daddr ${dmz_addr}/24 tcp dport {80, 443} accept comment "dmz to traefik"
    #
    #                     log prefix "Blocked INPUT: " flags all drop
    #     	}
    #
    #             chain output {
    #                     type filter hook output priority filter ; policy drop;
    #
    #     		ct state vmap { invalid : drop, established : accept, related : accept, new : jump output-allow, untracked : jump output-allow }
    #             }
    #
    #             chain output-allow {
    #                     udp dport  53 accept comment "DNS request"
    #                     udp dport 123 accept comment "NTP request"
    #                     icmp type echo-request accept comment "allow ping"
    #
    #                     # crowdsec
    #                     oifname lo ip daddr 127.0.0.1 tcp dport 8080 accept comment "crowdsec API"
    #                     oifname lo ip daddr 127.0.0.1 tcp dport 6060 accept comment "crowdsec API"
    #
    #                     oifname vlan-dmz tcp dport {80, 443} accept comment "hype10 to HTTP/HTTPS"
    #                     oifname ve-adguard ip saddr 192.168.240.16 ip daddr 192.168.241.1 tcp dport 3000 accept comment "traefik to adguard"
    #                     oifname ve-homepage ip saddr 192.168.240.16 ip daddr 192.168.241.2 tcp dport 8082 accept comment "traefik to homepage"
    #
    #                     log prefix "Blocked OUTPUT: " flags all drop
    #             }
    #
    #     	chain forward {
    #     		type filter hook forward priority filter; policy drop;
    #     		ct state vmap { invalid : drop, established : accept, related : accept, new : jump forward-allow, untracked : jump forward-allow }
    #
    #                     log prefix "Blocked FORWARD: " flags all drop
    #     	}
    #
    #     	chain forward-allow {
    #     		ct status dnat accept comment "allow port forward"
    #
    #                     iifname ve-homepage oifname enp1s0 udp dport 53
    #     	}
    #     }
    #   '';
    # };
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
  system.stateVersion = "25.05";
}
