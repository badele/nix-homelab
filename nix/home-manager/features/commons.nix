{ config
, inputs
, lib
, outputs
, pkgs
, ...
}:
{
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
    tmux

    # MQTT
    mqttui
    mosquitto

    nvd # Show diff nix packages
    nix-diff # Check derivation differences

    # Editor
    neovim

    # Colors
    pastel ## Colors generator
    grc ## colorize some commands results
    # TODO: Colout with 

    # Disk & File
    exa # ls alternative
    fd # find alternative
    du-dust # du rust version
    duf # df go version

    bat # cat alternative
    httpie # curl alternative
    ranger # TUI file manager
    bashmount # Terminal mount helper

    #    procs # top alternative
    atop # Top alternative
    btop # Top alternative

    ripgrep # Better grep
    jq # JSON pretty printer and manipulator
    sops # Deployment secrets tool

    # System
    ltrace # System trace
    strace # Library trace
    usbutils # USB utils
    dig # DNS tools
  ];
}
