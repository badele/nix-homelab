{ config, lib, pkgs, ... }:
let
  borgbackup = config.homelab.borgBackup;
  borgRunScript = pkgs.writeShellScriptBin "my-borg" ''
    set -euo pipefail

    keyname="$1"
    shift

    export BORG_RSH="ssh -i /etc/ssh/ssh_host_ed25519_key"
    export BORG_PASSCOMMAND="cat /run/secrets/borgbackup/passphrase/$keyname"

    borg "$@"
  '';

in
{
  # Export BORG_REPO_BASE for borg commands
  environment.variables = { BORG_REPO_BASE = borgbackup.remote; };
  environment.systemPackages = [ borgRunScript pkgs.borgbackup ];

  systemd.tmpfiles.rules = [
    "d /data/borgbackup/ 0755 root root -"
    (lib.mkIf config.services.postgresql.enable
      "d /data/borgbackup/postgresql 0750 postgres postgres -")
  ];
}
