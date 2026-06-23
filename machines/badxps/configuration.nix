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
  internetMachine = self.clan.inventory.instances.internet.roles.default.machines.badxps;
  # Clan inventory may expose machine settings directly or through imported fragments.
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
  # udevadm info -q property -p /sys/class/net/<INTERFACE-NAME> | grep '^ID_PATH='
  # udevadm control --reload
  # udevadm trigger --subsystem-match=net
  systemd.network.links."10-usb-ethernet" = {
    matchConfig = {
      Path = "pci-0000:3a:00.0-usb-0:1.2:1.0";
      Driver = "r8152";
    };

    linkConfig = {
      Name = config.homelab.host.interface;
    };
  };

  systemd.network.links."10-wifi" = {
    matchConfig = {
      Path = "pci-0000:3b:00.0";
      Driver = "ath10k_pci";
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
          address = "192.168.240.224";
          prefixLength = 24;
        }
      ];

      "vlan-${config.homelab.vlans.dmz.name}".ipv4.addresses = [
        {
          address = "192.168.32.224";
          prefixLength = 24;
        }
      ];

      "vlan-${config.homelab.vlans.iot.name}".ipv4.addresses = [
        {
          address = "192.168.40.224";
          prefixLength = 24;
        }
      ];
    };
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
