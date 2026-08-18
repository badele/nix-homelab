{ inputName, ... }:
{
  sources = { };

  transforms = {
    cef_mikrotik_dhcp_enriched = {
      type = "remap";
      inputs = [ inputName ];
      source = ''
        vendor = to_string(.vendor) ?? (to_string(.deviceVendor) ?? "")
        event_name = to_string(.event_name) ?? (to_string(.name) ?? "")
        message = to_string(.msg) ?? ""

        if downcase(vendor) == "mikrotik" {
          .mikrotik_topics = split(event_name, ",")
          if length(.mikrotik_topics) > 0 {
            .mikrotik_topic_primary = .mikrotik_topics[0]
          }
          if length(.mikrotik_topics) > 1 {
            .mikrotik_topic_level = .mikrotik_topics[1]
          }
        }

        if downcase(vendor) == "mikrotik" && match(event_name, r'(^|,)dhcp(,|$)') {
          .risk_type = "mikrotik dhcp"
          .mikrotik_dhcp_message = message

          dhcp_match = parse_regex(message, r'(?i)^(?P<server>\S+)\s+DHCP\s+(?P<action>assigned|deassigned|offering|declined|conflict)\s+(?P<ip>\d{1,3}(?:\.\d{1,3}){3})(?:\s+for\s+(?P<mac>[0-9a-fA-F:]+)(?:\s+(?P<hostname>.*\S))?)?') ?? null
          if dhcp_match != null {
            .mikrotik_dhcp_server = dhcp_match.server
            .mikrotik_dhcp_action = downcase!(dhcp_match.action)
            .mikrotik_dhcp_ip = dhcp_match.ip

            mac = to_string(dhcp_match.mac)
            if mac != "" {
              .mikrotik_dhcp_mac = downcase!(mac)
            }

            hostname = to_string(dhcp_match.hostname)
            if hostname != "" {
              .mikrotik_dhcp_hostname = strip_whitespace!(hostname)
            }
          }
        }
      '';
    };
  };

  sinks = { };
}
