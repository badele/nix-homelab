{ pkgs, backupRoot }:

pkgs.writeShellApplication {
  name = "mikrotik-list-backup-for-router";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
  ];
  text = ''
    set -euo pipefail

    backup_root="${backupRoot}"

    usage() {
      echo "Usage: $(basename "$0") <router>" >&2
    }

    if [[ "$(id -un)" != "mikrotik" ]]; then
      echo "This command must be run as the mikrotik user." >&2
      echo "From root, use: su mikrotik -s /run/current-system/sw/bin/bash" >&2
      exit 1
    fi

    if [[ $# -ne 1 ]]; then
      usage
      exit 1
    fi

    router="$1"
    router_dir="$backup_root/$router"

    if [[ ! -d "$router_dir" ]]; then
      echo "Router backup directory not found: $router_dir" >&2
      exit 1
    fi

    find "$router_dir" -maxdepth 1 -type f -name '*.backup.age' -printf '%T@ %p\n' \
      | sort -rn \
      | cut -d ' ' -f 2- \
      | while read -r backup_file; do
          rsc_file="''${backup_file%.backup.age}.rsc.age"
          echo "  backup: $backup_file"
          if [[ -f "$rsc_file" ]]; then
            echo "  export: $rsc_file"
          else
            echo "  export: missing ($rsc_file)"
          fi
          echo ""
        done
  '';
}
