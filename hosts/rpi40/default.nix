{ lib
, ...
}: {
  imports = [
    ./hardware-configuration.nix

    # Users
    ../../users/root/nixos_passwd.nix
    ../../users/badele/nixos_passwd.nix
    # Commons
    ../../nix/nixos/features/term/base
    ../../nix/nixos/features/homelab

    # Roles
    ../../nix/nixos/roles # Automatically load service from <host.modules> sectionn from `homelab.json` file
    ../../nix/nixos/roles/prometheus/exporter/node.nix
  ];

  networking.hostName = "rpi40";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.11";
}
