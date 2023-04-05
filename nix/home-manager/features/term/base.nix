{ config
, inputs
, lib
, outputs
, pkgs
, ...
}:
{

  imports = [
    ./tools/inxi.nix
    ./tools/system.nix

    # Shell
    ./tools/starship.nix
    ./tools/zsh.nix

    # Misc
    ./tools/broot.nix
    ./tools/htop.nix
    ./tools/neofetch.nix
    ./tools/top
    ./tools/user-scripts
  ];

  systemd.user.startServices = "sd-switch";

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };


  # NOTE: By default all programs enabled for the all shells
  programs = {
    home-manager.enable = true;
    git.enable = true;
    nix-index.enable = true; # command not found and nix-locate

    # Autojump
    zoxide = {
      enable = true;
      options = [ "--cmd j" ];
    };

    # FZF
    fzf = {
      enable = true;
      enableZshIntegration = false; ## OMZ
      defaultCommand = "fd --type file --follow --hidden --exclude .git";
      historyWidgetOptions = [ "--sort" "--exact" ];
    };

    # Cheats navigators
    navi = {
      enable = true;
      settings = {
        cheats = {
          paths = [
            "~/ghq/github.com/badele/cheats"
          ];
        };
      };
    };
  };

  home.packages = with pkgs; [
    # Nix
    nixpkgs-fmt # Nix formatter
    nix-prefetch-github # Compute SHA256 github repository
    haskellPackages.nix-derivation # Analyse derivation with pretty-derivation < packagename.drv

    awscli
    up
    curl
    wget
    eva
    unzip

    nvd # Show diff nix packages
    nix-diff # Check derivation differences

    # Editor
    neovim

    # Colors
    pastel ## Colors generator
    grc ## colorize some commands results
    # TODO: Colout with 

    bat # cat alternative
    exa # ls alternative
    fd # find alternative
    httpie # curl alternative
    ranger # TUI file manager
    bashmount # Terminal mount helper

    #    procs # top alternative
    atop # Top alternative
    btop # Top alternative

    ripgrep # Better grep
    jq # JSON pretty printer and manipulator
    sops # Deployment secrets tool
  ];

  # home = {
  #   persistence = {
  #     "/persist/user/${config.home.username}" = {
  #       directories = [
  #         "Documents"
  #         "Downloads"
  #         "Pictures"
  #         "Videos"
  #       ];
  #       allowOther = true;
  #     };
  #   };
  # };
}
