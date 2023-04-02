{ config, lib, pkgs, ... }:
let
  cfg = config.services.uptime;
  roleName = "uptime";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
in
{
  imports = [
    ../modules/uptime.nix
    ../features/system/containers.nix
  ];

  services.uptime = {
    enable = roleEnabled;
    imageTag = "1.19.6";
    port = 8083;
    extraOptions = [
      "-p"
      "${toString cfg.port}:3001"
      "--dns"
      "${cfg.dns}"
      "-v"
      "/data/docker/uptime:/app/data"
    ];
  };
}

