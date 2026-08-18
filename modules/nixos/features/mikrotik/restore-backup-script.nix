{
  pkgs,
  ageKeyFile,
  sshKeyFile,
}:

pkgs.writeShellApplication {
  name = "mikrotik-restore-backup-file-for-router";
  runtimeInputs = with pkgs; [
    age
    coreutils
    openssh
  ];
  text = ''
    set -euo pipefail

    age_key="${ageKeyFile}"
    ssh_key="${sshKeyFile}"

    usage() {
      echo "Usage: $(basename "$0") <backup-or-export-file.age> <router-host>" >&2
    }

    if [[ "$(id -un)" != "mikrotik" ]]; then
      echo "This command must be run as the mikrotik user." >&2
      echo "From root, use: su mikrotik -s /run/current-system/sw/bin/bash" >&2
      exit 1
    fi

    if [[ $# -ne 2 ]]; then
      usage
      exit 1
    fi

    selected_file="$1"
    router_host="$2"
    work_dir="$(mktemp -d)"

    cleanup() {
      if [[ -n "''${backup_plain:-}" && -f "$backup_plain" ]]; then
        shred -u "$backup_plain" 2>/dev/null || rm -f "$backup_plain"
      fi
      if [[ -n "''${rsc_plain:-}" && -f "$rsc_plain" ]]; then
        shred -u "$rsc_plain" 2>/dev/null || rm -f "$rsc_plain"
      fi
      rm -rf "$work_dir"
    }
    trap cleanup EXIT

    if [[ "$selected_file" != /* ]]; then
      echo "File path must be absolute: $selected_file" >&2
      exit 1
    fi

    backup_dir="$(dirname "$selected_file")"
    selected_name="$(basename "$selected_file")"

    case "$selected_name" in
      *.backup.age)
        timestamp="''${selected_name%.backup.age}"
        ;;
      *.rsc.age)
        timestamp="''${selected_name%.rsc.age}"
        ;;
      *)
        echo "File must end with .backup.age or .rsc.age: $selected_file" >&2
        exit 1
        ;;
    esac

    router="$(basename "$backup_dir")"
    backup_file="$backup_dir/$timestamp.backup.age"
    rsc_file="$backup_dir/$timestamp.rsc.age"

    if [[ ! -f "$backup_file" ]]; then
      echo "Backup file not found: $backup_file" >&2
      exit 1
    fi

    if [[ ! -f "$rsc_file" ]]; then
      echo "Export file not found: $rsc_file" >&2
      exit 1
    fi

    backup_plain="$work_dir/$(basename "''${backup_file%.age}")"
    rsc_plain="$work_dir/$(basename "''${rsc_file%.age}")"
    remote_backup_name="restored-nix-homelab-$(basename "$backup_plain")"
    remote_rsc_name="restored-nix-homelab-$(basename "$rsc_plain")"

    age --decrypt --identity "$age_key" --output "$backup_plain" "$backup_file"
    age --decrypt --identity "$age_key" --output "$rsc_plain" "$rsc_file"

    scp -i "$ssh_key" -o IdentitiesOnly=yes \
      "$backup_plain" "backup@$router_host:$remote_backup_name"

    scp -i "$ssh_key" -o IdentitiesOnly=yes \
      "$rsc_plain" "backup@$router_host:$remote_rsc_name"

    printf '%s\n' \
      "Copied decrypted files for $router to backup@$router_host." \
      "" \
      "Run the restore manually on the MikroTik router:" \
      "" \
      "/file print where name~\"restored-nix-homelab-$timestamp\"" \
      "/system backup load name=$remote_backup_name" \
      "" \
      "Optional text import:" \
      "" \
      "/import file-name=$remote_rsc_name"
  '';
}
