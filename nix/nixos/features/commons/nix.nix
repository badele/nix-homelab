{ pkgs, inputs, lib, config, ... }:
let
  domain = config.networking.domain;
in
{
  # Proprietary software
  nixpkgs.config.unfree = true;
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;

  # Allow multiple cores to build packages
  # nixpkgs.config.enableParallelBuildingByDefault = true;

  nix = {
    # Add all flake inputs to registry / CMD: nix registry list 
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      substituters = [
        # "http://nixcache.${domain}:5000"
        # "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        # "nixcache.${domain}:nJYY2ypfR1pveSZnBuBjMb0oyCGFfjbnsMp1isRS9sg="
        # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };

    package = pkgs.nixUnstable;
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    nix-index
    gnumake
    cmake
    home-manager
  ];

  # Enable cron service
  services.cron = {
    enable = true;
    systemCronJobs = [
      # update nix-index database from https://github.com/Mic92/nix-index-database project
      "@reboot      badele    /home/badele/.nix-profile/bin/my-download-nixpkgs-cache-index"
    ];
  };

  # Show installed packages (https://www.reddit.com/r/NixOS/comments/fsummx/comment/fm45htj/?utm_source=share&utm_medium=web2x&context=3)
  environment.etc."installed-packages".text =
    let
      packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
