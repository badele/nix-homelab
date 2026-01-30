{ config, pkgs, lib, ... }: {
  ##############################################################################
  # Common user conf
  ##############################################################################

  imports = [
    # Apps
    ../../../nix/home-manager/apps/tools.nix
    ../../../nix/home-manager/apps/editor/neovim.nix
    ../../../nix/home-manager/apps/development/packages.nix
    ../../../nix/home-manager/apps/development/aider.nix
    ../../../nix/home-manager/apps/development/internet.nix
    ../../../nix/home-manager/apps/development/nix.nix
    ../../../nix/home-manager/apps/system/performance.nix
    ../../../nix/home-manager/apps/system/file.nix
  ];

  home = {
    username = lib.mkDefault "badele";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "22.11";

    userconf = {
      user = {
        gpg = {
          id = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
          url = "https://keybase.io/brunoadele/pgp_keys.asc";
          sha256 =
            "sha256:1hr53gj98cdvk1jrhczzpaz76cp1xnn8aj23mv2idwy8gcwlpwlg";
        };
      };
    };
  };

  programs = {
    git = {
      enable = true;
      signing = {
        key = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
        signByDefault = true;
      };

      settings = {
        user = {
          name = "Bruno Adelé";
          email = "brunoadele@gmail.com";
        };
        core.pager = "delta";
        interactive.difffilter = "delta --color-only --features=interactive";
        delta.side-by-side = true;
        delta.navigate = true;
        merge.conflictstyle = "diff3";
      };
    };
  };

  ##############################################################################
  # User packages
  ##############################################################################
  home.packages = with pkgs; [
    ##################################"
    # Container / Virtualization
    ##################################"
    lazydocker # docker terminal UI
    qemu # Virtual machine manager
  ];
}
