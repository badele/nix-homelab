{ lib, config, ... }:
let
  modName = "loki";
  modEnabled = builtins.elem modName config.homelab.currentHost.modules;
in
#lib.mkIf (modEnabled)
{
  imports = [
    ./loki.nix
    ./promtail.nix
  ];
}
