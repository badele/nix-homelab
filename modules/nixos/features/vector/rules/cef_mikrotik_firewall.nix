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
          .mikrotik_firewall_message = message

          if exists(.act) {
            .mikrotik_firewall_action = to_string(.act) ?? "unknown"
            del(.act)
          }

          details = message
          rule_match = parse_regex(message, r'^(?P<rule>[^:]+):\s*(?P<details>.*)$') ?? null
          if rule_match != null {
            rule = strip_whitespace!(rule_match.rule)
            if !match(rule, r'^(in|out|connection-state|src-mac|proto|len)$') {
              chain_match = parse_regex(rule, r'^(?P<message>.+?)\s+(?P<chain>input|output|forward)$') ?? null
              if chain_match != null {
                .mikrotik_firewall_message = strip_whitespace!(chain_match.message)
                .mikrotik_firewall_chain = chain_match.chain
              } else if match(rule, r'^(input|output|forward)$') {
                .mikrotik_firewall_chain = rule
              } else {
                .mikrotik_firewall_message = rule
              }
              details = rule_match.details
            }
          }

          in_match = parse_regex(details, r'(^|,\s*)in:(?P<value>.*?)(\s+out:|,|$)') ?? null
          if in_match != null {
            .mikrotik_firewall_in_interface = strip_whitespace!(in_match.value)
          }

          out_match = parse_regex(details, r'(^|\s+|,\s*)out:(?P<value>.*?)(,|$)') ?? null
          if out_match != null {
            .mikrotik_firewall_out_interface = strip_whitespace!(out_match.value)
          }

          state_match = parse_regex(details, r'(^|,\s*)connection-state:(?P<value>[^,\s]+)') ?? null
          if state_match != null {
            .mikrotik_firewall_connection_state = state_match.value
          }

          src_mac_match = parse_regex(details, r'(^|,\s*)src-mac\s+(?P<value>[0-9a-fA-F:]+)') ?? null
          if src_mac_match != null {
            .mikrotik_firewall_src_mac = downcase!(src_mac_match.value)
          }

          proto_match = parse_regex(details, r'(^|,\s*)proto\s+(?P<value>\d+)') ?? null
          if proto_match != null {
            .mikrotik_firewall_ip_protocol_number = proto_match.value
          }

          flow_with_ports_match = parse_regex(details, r'(?P<src_ip>\d{1,3}(?:\.\d{1,3}){3}):(?P<src_port>\d+)->(?P<dst_ip>\d{1,3}(?:\.\d{1,3}){3}):(?P<dst_port>\d+)') ?? null
          if flow_with_ports_match != null {
            .mikrotik_firewall_src_ip = flow_with_ports_match.src_ip
            .mikrotik_firewall_src_port = flow_with_ports_match.src_port
            .mikrotik_firewall_dst_ip = flow_with_ports_match.dst_ip
            .mikrotik_firewall_dst_port = flow_with_ports_match.dst_port
          } else {
            flow_match = parse_regex(details, r'(?P<src_ip>\d{1,3}(?:\.\d{1,3}){3})->(?P<dst_ip>\d{1,3}(?:\.\d{1,3}){3})') ?? null
            if flow_match != null {
              .mikrotik_firewall_src_ip = flow_match.src_ip
              .mikrotik_firewall_dst_ip = flow_match.dst_ip
            }
          }

          len_match = parse_regex(details, r'(^|,\s*)len\s+(?P<value>\d+)') ?? null
          if len_match != null {
            .mikrotik_firewall_packet_len = len_match.value
          }
        }
      '';
    };
  };

  sinks = { };
}
