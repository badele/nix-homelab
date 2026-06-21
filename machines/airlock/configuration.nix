{
  pkgs,
  self,
  ...
}:

# The Host configuration use the tag
# See the machines/flake-module.nix for the tag definition and usage
# in the clan-core module
#
# This host use KDE desktop environment

let
  # first time ssh
  buildHost = "192.168.254.179";
  internetMachine = self.clan.inventory.instances.internet.roles.default.machines.airlock;
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
      hostname = "airlock";
      description = "Family shared laptop";
      interface = "enp1s0";
      address = targetHost;
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
      ../../users/badele/fix/kde.nix

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
    ];
  };

  ##############################################################################
  # sadele User configuration
  ##############################################################################
  home-manager.users.sadele = {

    home.stateVersion = "26.05";

    # Pass flake inputs to home-manager modules
    _module.args.inputs = self.inputs;

    # home-manager imports
    imports = [
      # self.inputs.stylix.homeModules.stylix
      ##########################################################################
      # Commons User configuration
      ##########################################################################
      ../../users/sadele/base.nix

      ##########################################################################
      # Customize on this computer
      ##########################################################################

      # Base
      ../../modules/home-manager/base.nix
    ];
  };

  ##############################################################################
  # loadele User configuration
  ##############################################################################
  home-manager.users.loadele = {

    home.stateVersion = "26.05";

    # Pass flake inputs to home-manager modules
    _module.args.inputs = self.inputs;

    # home-manager imports
    imports = [
      # self.inputs.stylix.homeModules.stylix
      ##########################################################################
      # Commons User configuration
      ##########################################################################
      ../../users/loadele/base.nix

      ##########################################################################
      # Customize on this computer
      ##########################################################################

      # Base
      ../../modules/home-manager/base.nix
    ];
  };

  ##############################################################################
  # luadele User configuration
  ##############################################################################
  home-manager.users.luadele = {

    home.stateVersion = "26.05";

    # Pass flake inputs to home-manager modules
    _module.args.inputs = self.inputs;

    # home-manager imports
    imports = [
      # self.inputs.stylix.homeModules.stylix
      ../../modules/home-manager/base.nix
    ];
  };

  # clan.core.networking.targetHost = "root@${targetHost}";
  clan.core.networking.buildHost = "badele@${buildHost}";
}
