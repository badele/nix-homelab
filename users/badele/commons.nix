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
  # Packages
  ##############################################################################
  home.packages = with pkgs; [
    # MQTT
    mosquitto
    mqttui

    # Development
    go
    lua54Packages.luarocks
    nano
    nodejs
    stylua
    tree-sitter
    gh # Github CLI
    meld # Awesome diff tool

    # Cloud & co
    awscli2 # AWS CLI
    kubectl # Kubernetes CLI
    kubectx # Kubernetes CLI
    k9s # Kubernetes CLI
    kubernetes-helm # Helm
    argocd # ArgoCD CLI

    # Network
    ipcalc # IP subnetcalculator
    trippy # mtr traceroute alternative

    # Graphics
    geeqie
    gifsicle
    gimp
    imagemagick
    inkscape

    # Office
    discord
    libreoffice

    # Misc
    xclip

    # VPN
    wireguard-tools
  ];
}
