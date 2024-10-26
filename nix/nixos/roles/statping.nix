{ config, lib, pkgs, ... }:
let
  cfg = config.services.statping;
  roleName = "statping";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
in
{
  imports = [
    ../../modules/nixos/statping.nix # TODO: use nixosModules
    ../features/system/containers.nix
  ];

  services.statping = rec {
    enable = roleEnabled;
    imageTag = "v0.90.78";
    port = 8082;
    extraOptions = [
      "-p"
      "${toString cfg.port}:8080"
      "-v"
      "/data/docker/statping:/app"

    ];
  };
}
