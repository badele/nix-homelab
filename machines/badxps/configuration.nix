{
  config,
  pkgs,
  self,
  ...
}:

# The Host configuration use the tag
# See the machines/flake-module.nix for the tag definition and usage
# in the clan-core module
#
# This host use I3

let
  # Clan inventory may expose machine settings directly or through imported fragments.
  internetMachine = self.clan.inventory.instances.internet.roles.default.machines.badxps;
  lanMacAddress = "3c:18:a0:d4:e2:d8";
  targetIP =
    if internetMachine.settings ? host then
      internetMachine.settings.host
    else
      (builtins.head (builtins.head internetMachine.settings.imports).imports).host;
in
{
  programs.zsh.enable = true;

  # Make userconf options available to all Home Manager users on this host.
  home-manager.sharedModules = [
    ../../modules/home-manager/modules/userconf.nix
  ];

  homelab = {
    nameServer = targetIP;
    host = {
      hostname = "badxps";
      description = "main badele laptop";
      interface = config.homelab.vlans.lan.name;
      address = "192.168.254.179"; # TODO: use targetIP
      gateway = "192.168.254.254";

      nproc = 4;
    };

    features = {
      homelab-summary.enable = true;
      tailscale.enable = false;
    };
  };

  # rename network devices
  # udevadm info -q property -p /sys/class/net/* | grep 'ID_NET_NAME_MAC'
  # sudo udevadm control --reload
  # sudo udevadm trigger --subsystem-match=net
  systemd.network = {
    links = {
      "10-usb-ethernet" = {
        matchConfig = {
          MACAddress = lanMacAddress;
          Driver = "r8152";
        };

        linkConfig = {
          Name = config.homelab.host.interface;
        };
      };

      "10-wifi" = {
        matchConfig = {
          Path = "pci-0000:3b:00.0";
          Driver = "ath10k_pci";
        };

        linkConfig = {
          Name = "wifi";
        };
      };
    };

    networks = {
      "40-br-lan" = {
        matchConfig.Name = "br-lan";
        dhcpV4Config.UseDomains = "route";
        # dns = [ "192.168.${toString config.homelab.vlans.lan.id}.${dnsServer}" ];
        # domains = [ "~${config.homelab.domain}" ];
        # networkConfig.DNSDefaultRoute = false;
      };

      # "40-br-mgmt" = {
      #   matchConfig.Name = "br-mgmt";
      #   dhcpV4Config.UseDomains = "route";
      #   # dns = [ "192.168.${toString config.homelab.vlans.mgmt.id}.${dnsServer}" ];
      #   # domains = [ "~mgmt.${config.homelab.domain}" ];
      #   # networkConfig.DNSDefaultRoute = false;
      # };

      # "40-br-dmz" = {
      #   matchConfig.Name = "br-dmz";
      #   dhcpV4Config.UseDomains = "route";
      #   # dns = [ "192.168.${toString config.homelab.vlans.dmz.id}.${dnsServer}" ];
      #   # domains = [ "~dmz.${config.homelab.domain}" ];
      #   # networkConfig.DNSDefaultRoute = false;
      # };

      # "40-br-infra" = {
      #   matchConfig.Name = "br-infra";
      #   dhcpV4Config.UseDomains = "route";
      #   # dns = [ "192.168.${toString config.homelab.vlans.infra.id}.${dnsServer}" ];
      #   # domains = [ "~infra.${config.homelab.domain}" ];
      #   # networkConfig.DNSDefaultRoute = false;
      # };

      # "40-br-iot" = {
      #   matchConfig.Name = "br-iot";
      #   dhcpV4Config.UseDomains = "route";
      #   # dns = [ "192.168.${toString config.homelab.vlans.iot.id}.${dnsServer}" ];
      #   # domains = [ "~iot.${config.homelab.domain}" ];
      #   # networkConfig.DNSDefaultRoute = false;
      # };
    };
  };

  networking = {
    networkmanager.unmanaged = [
      "interface-name:${config.homelab.vlans.lan.name}"
      "interface-name:vlan-${config.homelab.vlans.mgmt.name}"
      "interface-name:vlan-${config.homelab.vlans.dmz.name}"
      "interface-name:vlan-${config.homelab.vlans.infra.name}"
      "interface-name:vlan-${config.homelab.vlans.iot.name}"
      "interface-name:br-lan"
      "interface-name:br-mgmt"
      "interface-name:br-dmz"
      "interface-name:br-infra"
      "interface-name:br-iot"
    ];

    # hexa speak database
    # https://github.com/badele/ipv6-hexaspeak
    vlans = {
      # IPv6 hexa speak => bootable == fdca:5a00:b007:ab1e/64
      "vlan-${config.homelab.vlans.mgmt.name}" = {
        id = config.homelab.vlans.mgmt.id;
        interface = config.homelab.host.interface;
      };

      # IPv6 hexa speak => dead face == fdca:5a00:dead:face/64
      "vlan-${config.homelab.vlans.dmz.name}" = {
        id = config.homelab.vlans.dmz.id;
        interface = config.homelab.host.interface;
      };

      # IPv6 hexa speak => code base == fdca:5a00:c0de:ba5e/64
      "vlan-${config.homelab.vlans.infra.name}" = {
        id = config.homelab.vlans.infra.id;
        interface = config.homelab.host.interface;
      };

      # IPv6 hexa speak => data feed == fdca:5a00:da7a:feed/64
      "vlan-${config.homelab.vlans.iot.name}" = {
        id = config.homelab.vlans.iot.id;
        interface = config.homelab.host.interface;
      };
    };

    defaultGateway = {
      address = config.homelab.host.gateway;
      interface = "br-lan";
    };

    bridges = {
      br-lan.interfaces = [ config.homelab.vlans.lan.name ];
      br-mgmt.interfaces = [ "vlan-${config.homelab.vlans.mgmt.name}" ];
      br-dmz.interfaces = [ "vlan-${config.homelab.vlans.dmz.name}" ];
      br-infra.interfaces = [ "vlan-${config.homelab.vlans.infra.name}" ];
      br-iot.interfaces = [ "vlan-${config.homelab.vlans.iot.name}" ];
    };

    interfaces = {
      "${config.homelab.vlans.lan.name}" = { };
      "vlan-${config.homelab.vlans.mgmt.name}" = { };
      "vlan-${config.homelab.vlans.dmz.name}" = { };
      "vlan-${config.homelab.vlans.infra.name}" = { };
      "vlan-${config.homelab.vlans.iot.name}" = { };

      br-lan = {
        useDHCP = true;
        # ipv4.addresses = [
        #   {
        #     address = config.homelab.host.address;
        #     prefixLength = 24;
        #   }
        # ];
      };

      br-mgmt = {
        useDHCP = true;
        # ipv4.addresses = [
        #   {
        #     address = "192.168.240.224";
        #     prefixLength = 24;
        #   }
        # ];
      };

      br-dmz = {
        useDHCP = true;
        # ipv4.addresses = [
        #   {
        #     address = "192.168.32.224";
        #     prefixLength = 24;
        #   }
        # ];
      };

      br-infra = {
        useDHCP = true;
        # ipv4.addresses = [
        #   {
        #     address = "192.168.244.224";
        #     prefixLength = 24;
        #   }
        # ];
      };

      br-iot = {
        useDHCP = true;
        # ipv4.addresses = [
        #   {
        #     address = "192.168.40.224";
        #     prefixLength = 24;
        #   }
        # ];
      };
    };
  };

  boot.kernelModules = [ "tun" ];

  # This is required for qemu to be able to use the bridge networking on user-defined bridges.
  environment.etc."qemu/bridge.conf".text = ''
    allow br-lan
    allow br-mgmt
    allow br-dmz
    allow br-infra
    allow br-iot
  '';

  security.wrappers.qemu-bridge-helper = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.qemu}/libexec/qemu-bridge-helper";
  };

  # Backup existing files with a timestamp to avoid backup name collisions.
  home-manager.backupCommand = pkgs.writeShellScript "hm-backup-command" ''
    target="$1"
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_path="''${target}.hm-backup-''${timestamp}"

    if [ -e "''${backup_path}" ]; then
      backup_path="''${backup_path}-$$"
    fi

    mv -- "''${target}" "''${backup_path}"
  '';

  ##############################################################################
  # badele User configuration
  ##############################################################################

  # Enable ZSH NixosConfiguration
  users.users.badele.shell = pkgs.zsh;

  home-manager.users.badele = {

    home.stateVersion = "26.05";

    # Pass flake inputs to home-manager modules
    _module.args.inputs = self.inputs;

    # home-manager imports
    imports = [
      self.inputs.stylix.homeModules.stylix

      ##########################################################################
      # Commons User configuration
      ##########################################################################
      ../../users/badele/base.nix
      ../../users/badele/term.nix
      ../../users/badele/dev.nix
      ../../users/badele/desktop.nix
      ../../users/badele/system.nix

      ##########################################################################
      # Customize on this computer
      ##########################################################################

      # Base
      ../../modules/home-manager/base.nix

      # Bluetooth
      ../../modules/home-manager/term/bluetooth.nix

      # Security (GPG, SSH)
      ../../modules/home-manager/term/security/gpg.nix
      ../../modules/home-manager/term/security/pass.nix
      ../../modules/home-manager/term/security/ssh.nix

      # Networking
      ../../modules/home-manager/term/packages/networking.nix

      # Desktop Apps
      # ../../home-manager/desktop/apps/cad.nix
      # ../../home-manager/desktop/apps/chess.nix
      # ../../home-manager/desktop/apps/graphics.nix
      # ../../home-manager/desktop/apps/vscode.nix

      # Multimedia
      # ../../home-manager/desktop/apps/spotify.nix

      # Web browser
      # ../../home-manager/desktop/apps/google-chrome.nix
      # ../../users/badele/modules/firefox.nix

      # Xorg and Window Manager
      ../../modules/home-manager/desktop/xorg/base.nix
      ../../modules/home-manager/desktop/xorg/wm/i3.nix
      ../../modules/home-manager/desktop/apps/base.nix
    ];
  };

  clan.core.networking.targetHost = "root@${targetIP}";
}
