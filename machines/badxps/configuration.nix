{
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
  targetIP = self.clan.inventory.instances.internet.roles.default.machines.badxps.settings.host;
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
      interface = "enp1s0";
      address = targetIP;
      gateway = "192.168.254.254";

      nproc = 4;
    };

    features = {
      homelab-summary.enable = true;
      tailscale.enable = false;
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
