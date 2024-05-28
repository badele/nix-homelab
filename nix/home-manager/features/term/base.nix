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

    # Shell
    # ./tools/starship.nix
    ./tools/zsh.nix

    # # Misc
    ./tools/broot.nix
    ./tools/htop.nix
    ./tools/neofetch.nix
    ./tools/top
    ./tools/user-scripts
  ];

  systemd.user.startServices = "sd-switch";

  nixpkgs = {
    # overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = lib.mkForce pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };


  # # NOTE: By default all programs enabled for the all shells
  programs = {
    home-manager.enable = true;
    git.enable = true;
    nix-index.enable = true; # command not found and nix-locate

    # Autojump
    zoxide = {
      enable = true;
      options = [ "--cmd c" ];
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
            "$HOME/ghq/github.com/badele/cheats"
            "$HOME/ghq/github.com/denisidoro/cheats"
            "$HOME/ghq/github.com/denisidoro/navi-tldr-pages"
            "$HOME/ghq/github.com/denisidoro/dotfiles"
            "$HOME/ghq/github.com/mrVanDalo/navi-cheats"
            "$HOME/ghq/github.com/chazeon/my-navi-cheats"
            "$HOME/ghq/github.com/caojianhua/MyCheat"
            "$HOME/ghq/github.com/Kidman1670/cheats"
            "$HOME/ghq/github.com/isene/cheats"
            "$HOME/ghq/github.com/m42martin/navi-cheats"
            "$HOME/ghq/github.com/infosecstreams/cheat.sheets"
            "$HOME/ghq/github.com/prx2090/cheatsheets-for-navi"
            "$HOME/ghq/github.com/papanito/cheats"
            "$HOME/ghq/github.com/esp0xdeadbeef/cheat.sheets"
          ];
        };
      };
    };
  };

  home.packages = with pkgs ; [ ];
}
