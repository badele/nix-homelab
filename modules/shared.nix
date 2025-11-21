{
  clan-core,
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    self.nixosModules.homelab

    ../modules/system/yubikey.nix
    ../modules/virtualisation/podman.nix
  ];

  console.keyMap = "fr"; # French keyboard layout

  # Enable proprietary firmware
  hardware.enableRedistributableFirmware = true;

  # for detecting port scan with vector & reaction
  networking.firewall.logRefusedConnections = true;

  # Enable earlyoom to improve system responsiveness under low memory conditions
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 10; # Déclenche quand <5% de RAM libre
    freeSwapThreshold = 100; # Pas de swap, donc on met 100
  };

  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true; # Allow unfree packages system-wide
      allowUnfreePredicate = (_: true); # Allow all unfree packages
    };
    # Apply custom overlays globally for all machines
    overlays = import ../overlays/default.nix { inherit (self) inputs; };
  };

  nix = {
    # Garbage collection settings
    gc.automatic = true; # Enable automatic garbage collection
    gc.dates = "weekly"; # Run garbage collection weekly
    gc.options = "--delete-older-than 30d"; # Delete generations older than 30 days

    # Flake registry configuration
    # Add all flake inputs to registry / CMD: nix registry list
    registry = lib.mapAttrs (_: value: { flake = value; }) self.inputs;

    # Legacy nix path configuration
    # Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # Nix package version
    package = lib.mkForce pkgs.nix; # Force use of nixpkgs nix package

    # Nix settings
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false; # Don't warn about dirty git repositories
    };
  };
}
