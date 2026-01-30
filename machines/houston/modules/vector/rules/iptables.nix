{
  sources = {
    journald_kernel = {
      type = "journald";
      include_matches = {
        "_TRANSPORT" = [ "kernel" ];
      };
    };
  };

  transforms = {
    iptables_cleaned = {
      type = "remap";
      inputs = [ "journald_kernel" ];
      source = ''
        .unix_timestamp = .__REALTIME_TIMESTAMP
        .service = "iptables"
        .transport = ._TRANSPORT

        .meta = {}
        .meta.risk_level = "unknown"
        .meta.risk_type = "unknown"
        .meta.data_type = "unknown"
        .meta.data_value = "unknown"
        .meta.ip = "unknown"

        del(._BOOT_ID)
        del(._SOURCE_BOOTTIME_TIMESTAMP)
        del(.SYSLOG_FACILITY)
        del(.__SEQNUM_ID)
        del(.__MONOTONIC_TIMESTAMP)
        del(.SYSLOG_IDENTIFIER)
        del(._HOSTNAME)
        del(.__SEQNUM)
        del(.__CURSOR)
        del(.MESSAGE)
        del(._TRANSPORT)
        del(._RUNTIME_SCOPE)
        del(._SOURCE_MONOTONIC_TIMESTAMP)
        del(.PRIORITY)
        del(._MACHINE_ID)
        del(.__REALTIME_TIMESTAMP)
        del(._SOURCE_BOOTTIME_TIMESTAMP)
        del(._SOURCE_MONOTONIC_TIMESTAMP)

        ########################################################################
        # Critical avec classification par type
        ########################################################################

        # Port scan
        if .message != null && .message != "" {
          if match!(.message, r'(?i)refused connection: .* SRC=')  {
              .meta.risk_level = "critical"
              .meta.risk_type = "port scan"
          }
        }

        ########################################################################
        # No risk
        ########################################################################
        if .meta.risk_level == "unknown" && .message != null && .message != "" {
          .meta.risk_level = "none"
        }

        # Extract IP if present
        ip_match = parse_regex(.message, r'SRC=(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') ?? null
        if (ip_match != null) {
          .meta.ip = ip_match.ip
        } else {
          .meta.ip = "unknown"  # Fallback pour créer le chemin
        }
      '';
    };
  };
}
