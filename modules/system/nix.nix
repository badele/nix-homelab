{ pkgs, inputs, lib, config, ... }:
let
  domain = config.networking.domain;
in
{
  nix = {
    settings = {
      substituters = [
        "http://bootstore.${domain}:5000"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "bootstore.${domain}:nJYY2ypfR1pveSZnBuBjMb0oyCGFfjbnsMp1isRS9sg="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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
  ];

  # Enable cron service
  services.cron = {
    enable = true;
    systemCronJobs = [
      # update nix-index database from https://github.com/Mic92/nix-index-database project
      "@reboot      badele    /home/badele/.nix-profile/bin/my-download-nixpkgs-cache-index"
    ];
  };

  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.unfree = true;
}
