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

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== cardno:18_150_451"
  ];

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
    overlays = [
      self.inputs.nur.overlays.default
    ]
    ++ (import ../overlays/default.nix { inherit (self) inputs; });
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
