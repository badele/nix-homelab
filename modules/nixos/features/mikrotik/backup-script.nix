{
  pkgs,
  serviceName,
  routersFile,
  backupRoot,
  sshKeyFile,
  generatedAgeRecipientFile,
  configuredAgeRecipient,
  retention,
}:

pkgs.writeShellApplication {
  name = serviceName;
  runtimeInputs = with pkgs; [
    age
    coreutils
    findutils
    jq
    openssh
  ];
  text = ''
    set -euo pipefail

    routers_file="${routersFile}"
    backup_root="${backupRoot}"
    ssh_key="${sshKeyFile}"
    generated_age_recipient_file="${generatedAgeRecipientFile}"
    configured_age_recipient="${configuredAgeRecipient}"
    retention="${toString retention}"

    if [[ -n "$configured_age_recipient" ]]; then
      age_recipient="$configured_age_recipient"
    else
      age_recipient="$(cat "$generated_age_recipient_file")"
    fi

    mkdir -p "$backup_root"

    jq -c '.[]' "$routers_file" | while read -r router; do
      name="$(jq -r '.name' <<< "$router")"
      host="$(jq -r '.host' <<< "$router")"
      port="$(jq -r '.port' <<< "$router")"
      user="$(jq -r '.user' <<< "$router")"
      timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
      remote_base="nix-homelab-$name-$timestamp"
      router_dir="$backup_root/$name"
      work_dir="$(mktemp -d)"

      cleanup() {
        rm -rf "$work_dir"
      }
      trap cleanup EXIT

      echo "Backing up $name ($host:$port)"
      mkdir -p "$router_dir"

      ssh -n \
        -i "$ssh_key" \
        -p "$port" \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new \
        "$user@$host" \
        "/system backup save name=$remote_base; /export show-sensitive file=$remote_base"

      scp \
        -i "$ssh_key" \
        -P "$port" \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new \
        "$user@$host:$remote_base.backup" \
        "$work_dir/$remote_base.backup"

      scp \
        -i "$ssh_key" \
        -P "$port" \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new \
        "$user@$host:$remote_base.rsc" \
        "$work_dir/$remote_base.rsc"

      age --encrypt --recipient "$age_recipient" \
        --output "$router_dir/$timestamp.backup.age" \
        "$work_dir/$remote_base.backup"

      age --encrypt --recipient "$age_recipient" \
        --output "$router_dir/$timestamp.rsc.age" \
        "$work_dir/$remote_base.rsc"

      chmod 0640 "$router_dir/$timestamp.backup.age" "$router_dir/$timestamp.rsc.age"

      find "$router_dir" -maxdepth 1 -type f -name '*.backup.age' -printf '%T@ %p\n' \
        | sort -rn \
        | tail -n "+$((retention + 1))" \
        | cut -d ' ' -f 2- \
        | xargs -r rm -f

      find "$router_dir" -maxdepth 1 -type f -name '*.rsc.age' -printf '%T@ %p\n' \
        | sort -rn \
        | tail -n "+$((retention + 1))" \
        | cut -d ' ' -f 2- \
        | xargs -r rm -f

      cleanup
      trap - EXIT
    done
  '';
}
