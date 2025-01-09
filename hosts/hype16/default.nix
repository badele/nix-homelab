# #########################################################
# NIXOS (hosts)
##########################################################
{ lib, config, pkgs, ... }:
let
  netlan = "254";
  netadm = "240";
  netdmz = "32";

  ctradm = "241";

  # Host
  traefikIpSuffix = "16";
  adguardIpSuffix = "97";
  homepageIpSuffix = "98";
  triliumIpSuffix = "99";

  hype16_lan = "192.168.${netlan}.${traefikIpSuffix}";
  hype16_adm = "192.168.${netadm}.${traefikIpSuffix}";
  hype16_dmz = "192.168.${netdmz}.${traefikIpSuffix}";

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
    ../../nix/nixos/features/commons
    ../../nix/nixos/features/homelab
    # ../../nix/nixos/features/system/containers.nix

    # Virtualisation
    # ../../nix/nixos/features/virtualisation/podman.nix
    # ../../nix/nixos/features/virtualisation/docker.nix

    # Services
    # ../../nix/nixos/services/crowdsec.nix
    ../../nix/nixos/services/fail2ban.nix
    (import ../../nix/nixos/services/traefik.nix {
      inherit lib config;
      lan_address = hype16_lan;
      adm_address = hype16_adm;
      dmz_address = hype16_dmz;
    })

    # Containers
    (import ../../nix/nixos/containers/adguard.nix {
      inherit lib config pkgs;
      containerIpSuffix = adguardIpSuffix;
    })
    (import ../../nix/nixos/containers/homepage.nix {
      inherit pkgs;
      containerIpSuffix = homepageIpSuffix;
    })
    (import ../../nix/nixos/containers/trilium.nix {
      inherit pkgs;
      containerIpSuffix = triliumIpSuffix;
    })

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
    nameservers = [ "192.168.241.97" "9.9.9.11" ];

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
      #   iifname enp1s0 ip saddr 192.168.254.0/24 ip daddr ${hype16_lan}/24 tcp dport {80, 443} accept comment "lan to traefik"
      #   iifname vlan-adm ip saddr 192.168.254.0/24 ip daddr ${hype16_adm}/24 tcp dport {80, 443} accept comment "adm to traefik"
      #   iifname vlan-dmz ip saddr 192.168.254.0/24 ip daddr ${hype16_dmz}/24 tcp dport {80, 443} accept comment "dmz to traefik"
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

                        # Internet to DMZ
                        iifname vlan-dmz ip daddr 192.168.32.16 tcp dport {80, 443} accept comment "internet to DMZ traefik"

                        # LAN To traefik service
                        iifname enp1s0   ip saddr 192.168.${netlan}.0/24 ip daddr ${hype16_lan} tcp dport {80, 443} accept comment "lan to traefik"
                        iifname vlan-adm ip saddr 192.168.${netlan}.0/24 ip daddr ${hype16_adm} tcp dport {80, 443} accept comment "adm to traefik"
                        iifname vlan-dmz ip saddr 192.168.${netlan}.0/24 ip daddr ${hype16_dmz} tcp dport {80, 443} accept comment "dmz to traefik"

                        # LAN to adguard DNS
                        ip saddr 192.168.${netlan}.0/24 ip daddr 192.168.${netadm}.${adguardIpSuffix} udp dport {53} accept comment "adm to adguard DNS"
                        ip saddr 192.168.${netlan}.0/24 ip daddr 192.168.${netadm}.${adguardIpSuffix} tcp dport {53} accept comment "adm to adguard DNS"

                        #######################################################
                        # Homepage
                        #######################################################
                        iifname ve-homepage ip daddr ${hype16_adm} tcp dport {443} accept comment "homepage to traefik"

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

                        #######################################################
                        # Hype16
                        #######################################################
                        oifname vlan-dmz ip saddr ${hype16_dmz} tcp dport {80, 443} accept comment "hype16 to HTTP/HTTPS"

                        # oifname vlan-dmz ip saddr ${hype16_dmz} ip daddr 192.168.${ctradm}.${adguardIpSuffix} tcp dport {3000} accept comment "hype16 to adguard"

                        oifname ve-adguard ip saddr 192.168.${netadm}.${adguardIpSuffix} ip daddr 192.168.${ctradm}.${adguardIpSuffix} tcp dport {3000} accept comment "hype16 to adguard"

                        #######################################################
                        # Homepage
                        #######################################################
                        oifname ve-homepage ip saddr ${hype16_dmz} ip daddr 192.168.${ctradm}.${homepageIpSuffix} tcp dport 8082 accept comment "traefik to homepage"
                        oifname ve-homepage ip saddr 192.168.${netadm}.${homepageIpSuffix} ip daddr 192.168.${ctradm}.${homepageIpSuffix} tcp dport 8082 accept comment "traefik to homepage"

                        #######################################################
                        # Trilium
                        #######################################################
                        oifname ve-trilium ip saddr ${hype16_dmz} ip daddr 192.168.${ctradm}.${triliumIpSuffix} tcp dport 8080 accept comment "traefik to trilium"
                        oifname ve-trilium ip saddr 192.168.${netadm}.${triliumIpSuffix} ip daddr 192.168.${ctradm}.${triliumIpSuffix} tcp dport 8080 accept comment "traefik to trilium"

                        log prefix "Blocked OUTPUT: " flags all drop
                }

        	chain forward {
        		type filter hook forward priority filter; policy drop;
        		ct state vmap { invalid : drop, established : accept, related : accept, new : jump forward-allow, untracked : jump forward-allow }

                        log prefix "Blocked FORWARD: " flags all drop
        	}

        	chain forward-allow {
        		ct status dnat accept comment "allow port forward"

                        # ICMP
                        iifname vlan-dmz oifname ve-adguard icmp type echo-request accept comment "ping request vlan-dmz => ve-adguard"
                        iifname ve-adguard oifname vlan-dmz icmp type echo-request accept comment "ping request ve-adguard => vlan-dmz"

                        #######################################################
                        # Adguard
                        #######################################################
                        # NOTE: vlan-dmz is default route (out)
                        # in
                        iifname vlan-dmz oifname ve-adguard ip saddr 192.168.${netlan}.0/24 ip daddr 192.168.${ctradm}.${adguardIpSuffix} udp dport 53 accept comment "dmz to adguard DNS"
                        # out
                        iifname ve-adguard oifname vlan-dmz ip saddr 192.168.${ctradm}.${adguardIpSuffix} udp dport 53 accept comment "adguard out UDP DNS"
                        iifname ve-adguard oifname vlan-dmz ip saddr 192.168.${ctradm}.${adguardIpSuffix} tcp dport {443,853} accept comment "adguard out DNSEC/TLS"

                        #######################################################
                        # Homepage
                        #######################################################
                        iifname ve-homepage oifname vlan-dmz tcp dport {443} accept comment "homepage to external https"
                        iifname ve-homepage oifname ve-adguard udp dport {53} accept comment "homepage to adguard DNS"
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
