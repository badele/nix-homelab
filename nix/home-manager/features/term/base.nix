{ config, inputs, lib, pkgs, ... }: {

  imports = [
    # Hardware informations
    ./tools/inxi.nix

    # Shell
    ./tools/zsh.nix

    # # Misc
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
    # Add all flake inputs to registry / CMD: nix registry list
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    #Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
      config.nix.registry;

    package = lib.mkForce pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  # # NOTE: By default all programs enabled for the all shells
  programs = {
    yazi.enable = true; # Filemanager
    starship.enable = true; # Terminal prompt
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
      enableZshIntegration = false; # # OMZ
      defaultCommand = "fd --type file --follow --hidden --exclude .git";
      historyWidgetOptions = [ "--sort" "--exact" ];
    };

    # Cheats navigators
    # alias: lnavi (local search)
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

  home.packages = with pkgs; [
    act # Run your GitHub Actions locally
    delta # A syntax-highlighting pager for git
    ghq # Remote repository management made easy
    direnv # load environment when on the current directory
  ];

}
