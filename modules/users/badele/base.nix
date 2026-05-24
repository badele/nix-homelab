{

  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  home.userconf = {
    user = {
      contact = {
        name = "Bruno Adelé";
        email = "brunoadele@gmail.com";
      };

      gpg = {
        id = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
        url = "https://keys.openpgp.org/vks/v1/by-fingerprint/${config.home.userconf.user.gpg.id}";
        sha256 = "sha256:1n5ik324jv9qj7ikpp20fcczd9piijr93j5zrg1qkvw4a7xks7ad";
      };
    };
  };

  # You can preview the palette at ~/.config/stylix/palette.html
  stylix.enable = true;
  stylix.autoEnable = true;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-moon.yaml";
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
    sha256 = "sha256-xrLfcRkr6TjTW464GYf9XNFHRe5HlLtjpB0LQAh/l6M=";
  };

  systemd.user.startServices = "sd-switch";

  # nixpkgs = {
  #   config = {
  #     allowUnfree = true;
  #     allowUnfreePredicate = (_: true);
  #   };
  # };

  nix = {
    # Add all flake inputs to registry / CMD: nix registry list
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    #Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    package = lib.mkForce pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };
  programs.kitty.enable = true;

  # # NOTE: By default all programs enabled for the all shells
  programs = {
    starship.enable = true; # Terminal prompt
    home-manager.enable = true;
    git.enable = true;
    nix-index.enable = true; # command not found and nix-locate

    # Filemanager
    yazi = {
      enable = true;
      shellWrapperName = "y";
    };

    mise = {
      enable = true; # dev tools, env vars, task runner
      enableZshIntegration = true; # mise integration for zsh

      globalConfig.settings = {
        experimental = false;
        verbose = false;
        auto_install = true;
        all_compile = true;
      };

      globalConfig = {
      };
    };

    direnv = {
      enable = true; # load environment when on the current directory
      enableZshIntegration = true;
      silent = true;

      nix-direnv.enable = true; # direnv integration for nix-direnv
      mise.enable = true; # direnv integration for mise
    };

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
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
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

    bat # cat alternative
    curl # HTTP client
    dconf # Dconf editor

    eva # Calculator
    httpie # Curl alternative

    tmux # Terminal multiplexer
    up # UI interactively pipe
    wget # HTTP client
  ];

}
