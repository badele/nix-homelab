{ config, lib, pkgs, ... }:
let
  cfg = config.services.uptime;
  roleName = "uptime";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
in
{
  imports = [
    ../../modules/nixos/uptime.nix
    ../modules/system/containers.nix
  ];

  services.uptime = {
    enable = roleEnabled;
    imageTag = "1.19.6";
    extraOptions = [
      "-p"
      "8083:3001"
      "--dns"
      "${cfg.dns}"
      "-v"
      "/data/docker/uptime:/app/data"
    ];
  };
}

