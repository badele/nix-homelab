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
    ../modules/system/yubikey.nix
  ];

  console.keyMap = "fr"; # French keyboard layout

  # Enable proprietary firmware
  hardware.enableRedistributableFirmware = true;

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true; # Allow unfree packages system-wide
    allowUnfreePredicate = (_: true); # Allow all unfree packages
  };

  nix = {
    # Garbage collection settings
    gc.automatic = true; # Enable automatic garbage collection
    gc.dates = "daily"; # Run garbage collection daily
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
