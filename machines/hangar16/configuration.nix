{
  config,
  pkgs,
  self,
  ...
}:

# The Host configuration use the tag
# See the machines/flake-module.nix for the tag definition and usage
# in the clan-core module

let
  # first time ssh
  admSuffixIPv4 = "16";
  internetMachine = self.clan.inventory.instances.internet.roles.default.machines.hangar16;
  # Clan inventory may expose machine settings directly or through imported fragments.
  targetHost =
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
    nameServer = "192.168.254.154";
    host = {
      hostname = "hangar16";
      description = "Virtualization server for the homelab";
      interface = config.homelab.vlans.lan.name;
      address = "192.168.254.${admSuffixIPv4}";
      gateway = "192.168.254.254";

      nproc = 20;
    };

    features = {
      homelab-summary.enable = true;
      tailscale.enable = false;
    };
  };
  # rename network devices
  # udevadm info -q property -p /sys/class/net/<INTERFACE-NAME> | grep '^ID_PATH='
  # udevadm info -q property -p /sys/class/net/<INTERFACE-NAME> | grep 'DRIVER='
  # udevadm control --reload
  # udevadm trigger --subsystem-match=net
  systemd.network.links."10-usb-ethernet" = {
    matchConfig = {
      Path = "pci-0000:00:0d.0-usb-0:1:1.0";
      Driver = "r8152";
    };

    linkConfig = {
      Name = config.homelab.host.interface;
    };
  };

  systemd.network.links."10-wifi" = {
    matchConfig = {
      Path = "pci-0000:00:14.3";
      Driver = "iwlwifi";
    };

    linkConfig = {
      Name = "wifi";
    };
  };

  networking = {
    networkmanager.unmanaged = [
      "interface-name:${config.homelab.vlans.lan.name}"
      "interface-name:vlan-${config.homelab.vlans.adm.name}"
    ];

    vlans = {
      # IPv6 hexa speak => bootable == fdca:5a00:b007:ab1e/64
      "vlan-${config.homelab.vlans.adm.name}" = {
        id = config.homelab.vlans.adm.id;
        interface = config.homelab.host.interface;
      };

      # IPv6 hexa speak => dead face == fdca:5a00:dead:face/64
      "vlan-${config.homelab.vlans.dmz.name}" = {
        id = config.homelab.vlans.dmz.id;
        interface = config.homelab.host.interface;
      };

      # IPv6 hexa speak => data feed == fdca:5a00:da7a:feed/64
      "vlan-${config.homelab.vlans.iot.name}" = {
        id = config.homelab.vlans.iot.id;
        interface = config.homelab.host.interface;
      };
    };

    interfaces = {
      "${config.homelab.vlans.lan.name}".ipv4.addresses = [
        {
          address = config.homelab.host.address;
          prefixLength = 24;
        }
      ];

      "vlan-${config.homelab.vlans.adm.name}".ipv4.addresses = [
        {
          address = "192.168.240.${admSuffixIPv4}";
          prefixLength = 24;
        }
      ];

      "vlan-${config.homelab.vlans.dmz.name}".ipv4.addresses = [
        {
          address = "192.168.32.${admSuffixIPv4}";
          prefixLength = 24;
        }
      ];

      "vlan-${config.homelab.vlans.iot.name}".ipv4.addresses = [
        {
          address = "192.168.40.${admSuffixIPv4}";
          prefixLength = 24;
        }
      ];
    };
  };

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

      ##########################################################################
      # Customize on this computer
      ##########################################################################

      # Base
      ../../modules/home-manager/base.nix

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
    ];
  };

  clan.core.networking.targetHost = "root@${targetHost}";
  # clan.core.networking.buildHost = "badele@${buildHost}";
}
