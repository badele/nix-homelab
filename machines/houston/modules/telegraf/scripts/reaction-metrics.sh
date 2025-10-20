#!/run/current-system/sw/bin/bash

set -euo pipefail

@reaction@ show -f json | @jq@ -r '
.vector | 
to_entries | 
map({
  service: .key,
  total_matches: ([.value[] | select(has("matches")) | .matches] | add // 0),
  total_actions: [.value[] | select(has("actions") or has("ACTION")) | 1] | length
}) |
map(
  "reaction_matches,service=" + .service + " value=" + (.total_matches | tostring) + "\n" +
  "reaction_actions,service=" + .service + " value=" + (.total_actions | tostring)
) |
join("\n")
'

iptables_count=$(@sudo@ @iptables@ -vnL reaction 2>/dev/null | tail -n +3 | wc -l || echo 0)
ip6tables_count=$(@sudo@ @ip6tables@ -vnL reaction 2>/dev/null | tail -n +3 | wc -l || echo 0)

echo "reaction_iptables_entries,ip_version=4 value=${iptables_count}"
echo "reaction_iptables_entries,ip_version=6 value=${ip6tables_count}"
