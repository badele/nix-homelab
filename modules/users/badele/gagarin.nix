{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  username = "badele";
  extraGroups =
    [
      "audio"
      "video"
      "wheel"
    ]
    ++ ifTheyExist [
      "docker"
      "git"
      "incus-admin"
      "libvirtd"
      "network"
      "networkmanager"
      "plugdev"
      "qbittorrent-nox"
      "media"
    ];
in
{
  ############################################################################
  # NixOS configuration
  ############################################################################
  imports = [
    self.inputs.home-manager.nixosModules.default
  ];

  users.users."${username}" = {
    extraGroups = extraGroups;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  ############################################################################
  # home-manager configuration
  ############################################################################
  home-manager.users."${username}" = {

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };

    # home-manager imports
    imports = [
      self.inputs.stylix.homeManagerModules.stylix

      # Modules
      ../../home-manager/modules/userconf.nix

      # Bluetooth
      ../../home-manager/term/bluetooth.nix

      # Security (GPG, SSH)
      ../../home-manager/term/security

      # Homogen style (stylix)
      ../../home-manager/term/stylix.nix

      # Development
      ../../home-manager/term/development/aws.nix
      ../../home-manager/term/development/language/all.nix

      # Xorg and Window Manager
      ../../home-manager/desktop/xorg/base.nix
      ../../home-manager/desktop/xorg/wm/i3.nix
      ../../home-manager/desktop/apps/base.nix

      # Packages
      ./../../home-manager/term/packages/base.nix
      ./../../home-manager/term/packages/development.nix
      ./../../home-manager/term/packages/filesystem.nix
      ./../../home-manager/term/packages/networking.nix
      ./../../home-manager/term/packages/nix.nix
      ./../../home-manager/term/packages/performance.nix

      # Editor
      ../../home-manager/term/neovim.nix

      # Apps
      # ../../home-manager/desktop/cad.nix
      # ../../home-manager/desktop/chess.nix
      # ../../home-manager/desktop/graphics.nix
      # ../../home-manager/desktop/vscode.nix

      # Web browser
      ../../home-manager/desktop/apps/google-chrome.nix
      ../../users/badele/modules/firefox.nix

    ];
    nixpkgs.overlays = [ self.inputs.nur.overlay ];
    _module.args.nur = { inherit (self.inputs) nur; };

    home = {
      username = lib.mkDefault username;
      homeDirectory = lib.mkDefault "/home/${username}";
      stateVersion = lib.mkDefault "25.11";

      userconf = {
        user = {
          gpg = {
            id = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
            url = "https://keybase.io/brunoadele/pgp_keys.asc";
            sha256 = "sha256:1hr53gj98cdvk1jrhczzpaz76cp1xnn8aj23mv2idwy8gcwlpwlg";
          };
        };
      };
    };

    programs = {
      git = {
        enable = true;
        userName = "Bruno Adelé";
        userEmail = "brunoadele@gmail.com";
        signing = {
          key = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
          signByDefault = true;
        };

        extraConfig = {
          core.pager = "delta";
          interactive.difffilter = "delta --color-only --features=interactive";
          delta.side-by-side = true;
          delta.navigate = true;
          merge.conflictstyle = "diff3";
        };
      };
    };
  };
}
