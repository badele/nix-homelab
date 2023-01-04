{ config
, lib
, pkgs
, ...
}:
let
  modName = "nfs";
  modEnabled = lib.elem modName config.homelab.currentHost.modules;
in
lib.mkIf (modEnabled)
{
  # Active the nfs server
  services.nfs.server.enable = true;
  services.nfs.server.exports = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (hostname: host: ''/data/borgbackup/${hostname} ${host.ipv4}/32(async,rw,nohide,insecure,no_subtree_check)'')
    config.homelab.hosts);

  # Create host borgbackup folder
  systemd.tmpfiles.rules =
    (lib.mapAttrsToList (hostname: host: "d /data/borgbackup/${hostname} 0750 root root -") config.homelab.hosts);
}
