{ config, lib, ... }: {
  systemd.tmpfiles.rules = [ "d /data/borgbackup/ 0750 root root -" ];
}
