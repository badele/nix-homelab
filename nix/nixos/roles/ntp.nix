{ outputs, lib, config, ... }:
let
  roleName = "ntp";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
in
lib.mkIf (roleEnabled)
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
