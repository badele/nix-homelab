{ inputName, ... }:
{
  sources = { };

  transforms = {
    cef_mikrotik_login_enriched = {
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

        if downcase(vendor) == "mikrotik" && match(message, r'(?i)^login ') {
          .risk_type = "mikrotik login"
          .mikrotik_login_message = message

          user_match = parse_regex(message, r'(?i)for user (?P<value>\S+)') ?? null
          if user_match != null {
            .mikrotik_login_user = user_match.value
          } else if exists(.duser) {
            .mikrotik_login_user = to_string(.duser) ?? "unknown"
          }

          source_match = parse_regex(message, r'(?i) from (?P<value>\d{1,3}(?:\.\d{1,3}){3})') ?? null
          if source_match != null {
            .mikrotik_login_source_ip = source_match.value
          } else if exists(.src) {
            .mikrotik_login_source_ip = to_string(.src) ?? "unknown"
          }

          method_match = parse_regex(message, r'(?i) via (?P<value>\S+)') ?? null
          if method_match != null {
            .mikrotik_login_method = method_match.value
          } else if exists(.app) {
            .mikrotik_login_method = to_string(.app) ?? "unknown"
          }

          outcome = to_string(.outcome) ?? ""
          if downcase(outcome) == "failure" || match(message, r'(?i)login failure') {
            .risk_level = "critical"
          }
        }
      '';
    };
  };

  sinks = { };
}
