{ inputName, ... }:
{
  sources = { };

  transforms = {
    cef_mikrotik_firewall_enriched = {
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

        if downcase(vendor) == "mikrotik" && match(event_name, r'(^|,)firewall(,|$)') {
          .risk_type = "mikrotik firewall"
          .firewall_message = message

          details = message
          rule_match = parse_regex(message, r'^(?P<rule>[^:]+):\s*(?P<details>.*)$') ?? null
          if rule_match != null {
            rule = strip_whitespace!(rule_match.rule)
            if !match(rule, r'^(in|out|connection-state|src-mac|proto|len)$') {
              .mikrotik_rule = rule
              .firewall_message = rule
              details = rule_match.details
            }
          }

          in_match = parse_regex(details, r'(^|,\s*)in:(?P<value>[^,]+)') ?? null
          if in_match != null {
            .mikrotik_in_interface = strip_whitespace!(in_match.value)
          }

          out_match = parse_regex(details, r'(^|,\s*)out:(?P<value>[^,]+)') ?? null
          if out_match != null {
            .mikrotik_out_interface = strip_whitespace!(out_match.value)
          }

          state_match = parse_regex(details, r'(^|,\s*)connection-state:(?P<value>[^,\s]+)') ?? null
          if state_match != null {
            .mikrotik_connection_state = state_match.value
          }

          src_mac_match = parse_regex(details, r'(^|,\s*)src-mac\s+(?P<value>[0-9a-fA-F:]+)') ?? null
          if src_mac_match != null {
            .mikrotik_src_mac = downcase!(src_mac_match.value)
          }

          proto_match = parse_regex(details, r'(^|,\s*)proto\s+(?P<value>\d+)') ?? null
          if proto_match != null {
            .mikrotik_ip_protocol_number = proto_match.value
          }

          flow_match = parse_regex(details, r'(?P<src>\d{1,3}(?:\.\d{1,3}){3})->(?P<dst>\d{1,3}(?:\.\d{1,3}){3})') ?? null
          if flow_match != null {
            .mikrotik_source_ip = flow_match.src
            .mikrotik_destination_ip = flow_match.dst
          }

          len_match = parse_regex(details, r'(^|,\s*)len\s+(?P<value>\d+)') ?? null
          if len_match != null {
            .mikrotik_packet_len = len_match.value
          }
        }
      '';
    };
  };

  sinks = { };
}
