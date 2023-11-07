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
      # settings = {
      #   cheats = {
      #     paths = [
      #       "~/ghq/github.com/badele/cheats"
      #       "~/ghq/github.com/denisidoro/cheats"
      #       "~/ghq/github.com/denisidoro/navi-tldr-pages"
      #       "~/ghq/github.com/denisidoro/dotfiles"
      #       "~/ghq/github.com/mrVanDalo/navi-cheats"
      #       "~/ghq/github.com/chazeon/my-navi-cheats"
      #       "~/ghq/github.com/caojianhua/MyCheat"
      #       "~/ghq/github.com/Kidman1670/cheats"
      #       "~/ghq/github.com/isene/cheats"
      #       "~/ghq/github.com/m42martin/navi-cheats"
      #       "~/ghq/github.com/infosecstreams/cheat.sheets"
      #       "~/ghq/github.com/prx2090/cheatsheets-for-navi"
      #       "~/ghq/github.com/papanito/cheats"
      #       "~/ghq/github.com/esp0xdeadbeef/cheat.sheets"
      #     ];
      #   };
      # };
    };
  };

  home.packages = with pkgs ; [ ];
}
