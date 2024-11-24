{ config, pkgs, lib, ... }: {
  ##############################################################################
  # Common user conf
  ##############################################################################
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

  ##############################################################################
  # User packages
  ##############################################################################
  home.packages = with pkgs; [
    ##################################"
    # Tool
    ##################################"

    dconf # Dconf editor

    atop # Top alternative
    bat # cat alternative
    curl # HTTP client
    du-dust # du rust version
    duf # df go version
    eva # Calculator
    eza # ls alternative
    fd # find alternative
    httpie # curl alternative
    jq # JSON pretty printer and manipulator
    pastel # Colors generator
    ripgrep # Better grep
    tmux # Terminal multiplexer
    unzip # Unzip files
    up # UI interactively pipe
    wget # HTTP client

    # Floating apps (used in i3)
    bashmount # Terminal mount helper
    bluetuith # Bluetooth manager
    btop # Top alternative
    procs # Top alternative

    ##################################"
    # Development
    ##################################"

    # Makefile like
    just # justfile (Makefile like)

    # Git
    meld # Visual diff and merge tool
    lazygit # git terminal UI

    # Nix
    haskellPackages.nix-derivation # Analyse derivation with pretty-derivation < packagename.drv
    nix-prefetch-github # Compute SHA256 github repository
    nixpkgs-fmt # Nix formatter
    nix-diff # Check derivation differences
    nvd # Show diff nix packages

    ##################################"
    # Container / Virtualization
    ##################################"
    lazydocker # docker terminal UI
    qemu # Virtual machine manager
  ];
}
