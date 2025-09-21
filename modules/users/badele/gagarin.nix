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
  extraGroups = [
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
    uid = 1000;
    inherit extraGroups;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  ############################################################################
  # home-manager configuration
  ############################################################################
  home-manager.users."${username}" = {

    # Pass flake inputs to home-manager modules
    _module.args.inputs = self.inputs;

    # home-manager imports
    imports = [
      self.inputs.stylix.homeModules.stylix

      # Modules
      # ../../home-manager/modules/userconf.nix

      # Shared
      ../../home-manager/shared

      # Bluetooth
      ../../home-manager/term/bluetooth.nix

      # Security (GPG, SSH)
      ../../home-manager/term/security/pass.nix
      ../../home-manager/term/security/ssh.nix

      # Homogen style (stylix)
      # ../../home-manager/term/stylix.nix

      # Development
      ../../home-manager/term/development/aws.nix
      ../../home-manager/term/development/language/all.nix

      # Xorg and Window Manager
      ../../home-manager/desktop/xorg/base.nix
      ../../home-manager/desktop/xorg/wm/i3.nix
      ../../home-manager/desktop/apps/base.nix

      # Packages
      ./../../home-manager/term/packages/development.nix
      ./../../home-manager/term/packages/filesystem.nix
      ./../../home-manager/term/packages/networking.nix
      ./../../home-manager/term/packages/nix.nix
      ./../../home-manager/term/apps/system.nix

      # Term Apps
      ../../home-manager/term/apps/neovim.nix
      ../../home-manager/term/apps/system.nix

      # Desktop Apps
      # ../../home-manager/desktop/apps/cad.nix
      # ../../home-manager/desktop/apps/chess.nix
      # ../../home-manager/desktop/apps/graphics.nix
      # ../../home-manager/desktop/apps/vscode.nix

      # Multimedia
      ../../home-manager/desktop/apps/spotify.nix

      # Web browser
      # ../../home-manager/desktop/apps/google-chrome.nix
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

    home.packages = with pkgs; [
      gimp
      inkscape
      libreoffice

      hl-log-viewer # JSON and logfmt viewer
    ];

  };
}
