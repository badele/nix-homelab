{ outputs, lib, config, ... }:
let
  modName = "ntp";
  modEnabled = lib.elem modName config.homelab.currentHost.modules;
in
lib.mkIf (modEnabled)
{
  services.ntp = {
    enable = true;
    servers = [
      "0.fr.pool.ntp.org"
      "1.fr.pool.ntp.org"
      "2.fr.pool.ntp.org"
      "3.fr.pool.ntp.org"
    ];
  };
}
