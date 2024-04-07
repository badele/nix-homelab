{ pkgs, ... }:
{
  programs = {
    # TODO: remove ranger from package
    yazi.enable = true; # TUI file manager
  };

  home.packages = with pkgs; [
    # Nix
    haskellPackages.nix-derivation # Analyse derivation with pretty-derivation < packagename.drv
    nix-prefetch-github # Compute SHA256 github repository
    nixpkgs-fmt # Nix formatter

    nix-diff # Check derivation differences
    nvd # Show diff nix packages

    # Colors
    pastel ## Colors generator
    # grc ## colorize some commands results
    # TODO: Colout with

    # Disk & File
    du-dust # du rust version
    duf # df go version
    eza # ls alternative
    fd # find alternative

    # Floating apps
    bashmount # Terminal mount helper
    bluetuith # Bluetooth manager
    btop # Top alternative
    procs # Top alternative

    bat # cat alternative
    httpie # curl alternative
    ranger # TUI file manager

    #    procs # top alternative
    atop # Top alternative

    jq # JSON pretty printer and manipulator
    ripgrep # Better grep

    # Misc
    curl # HTTP client
    eva # Calculator
    tmux # Terminal multiplexer
    unzip # Unzip files
    up # UI interactively pipe
    wget # HTTP client
  ];
}
