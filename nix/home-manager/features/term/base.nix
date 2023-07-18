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
}
