{
  ...
}:
{
  # jq 'select(.meta.reducedmessage != null).meta.reducedmessage' /var/lib/vector/logs/risk-level-unknown.log | sort | uniq -c | sort -h
  services.vector = {
    enable = true;
    journaldAccess = true;
    settings = {
      data_dir = "/var/lib/vector";

      sources = {
        journald_ssh = {
          type = "journald";
          include_units = [
            "sshd"
            "sshd-session"
          ];
          # current_boot_only = true;
        };
        journald_kernel = {
          type = "journald";
          include_matches = {
            "_TRANSPORT" = [ "kernel" ];
          };
        };
      };

      transforms = {
        sshd_cleaned = {
          type = "remap";
          inputs = [ "journald_ssh" ];
          source = ''
            .unix_timestamp = .__REALTIME_TIMESTAMP
            .service = ._COMM
            .transport = ._TRANSPORT

            .meta = {}
            .meta.risk_level = "unknown"
            .meta.risk_type = "unknown"
            .meta.user = "unknown"
            .meta.ip = "unknown"

            del(.PRIORITY)
            del(.SYSLOG_FACILITY)
            del(.SYSLOG_IDENTIFIER)
            del(.SYSLOG_PID)
            del(.SYSLOG_TIMESTAMP)
            del(._BOOT_ID)
            del(._CAP_EFFECTIVE)
            del(._CMDLINE)
            del(._COMM)
            del(._EXE)
            del(._GID)
            del(._MACHINE_ID)
            del(._PID)
            del(._RUNTIME_SCOPE)
            del(._SOURCE_REALTIME_TIMESTAMP)
            del(._SYSTEMD_CGROUP)
            del(._SYSTEMD_INVOCATION_ID)
            del(._SYSTEMD_SLICE)
            del(._SYSTEMD_UNIT)
            del(._TRANSPORT)
            del(._UID)
            del(.__MONOTONIC_TIMESTAMP)
            del(.__REALTIME_TIMESTAMP)
            del(.__SEQNUM)
            del(.__SEQNUM_ID)

            # Extract user if present
            user_match = parse_regex(.message, r'(?i)user (?P<user>\w+)') ||
            parse_regex(.message, r'(?i)publickey for (?P<user>\w+)') ?? null
            if (user_match != null) {
              .meta.user = user_match.user
            }

            # Extract IP if present
            ip_match = parse_regex(.message, r'(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') ?? null
            if (ip_match != null) {
              .meta.ip = ip_match.ip
            } else {
              .meta.ip = "unknown"  # Fallback pour créer le chemin
            }

            ########################################################################
            # Critical avec classification par type
            ########################################################################

            # Login fail
            if .meta.ip != "unknown"  {
              if .message != null && .message != "" {
                if match!(.message, r'(?i)failed.*password') ||
                  match!(.message, r'(?i)authentication (?:failure|error|failed)') ||
                  match!(.message, r'(?i)invalid user') ||
                  match!(.message, r'(?i)maximum authentication attempts exceeded') ||
                  match!(.message, r'(?i)too many authentication failures') ||
                  match!(.message, r'(?i)user .* not allowed') ||
                  match!(.message, r'(?i)srclimit_penalise: .* new') ||
                  match!(.message, r'(?i)root login refused') {
                    .meta.risk_level = "critical"
                    .meta.risk_type = "login fail"
                } else 
                
                # DDOS
                if match!(.message, r'(?i)did not receive identification string') ||
                  match!(.message, r'(?i)timeout before authentication') ||
                  match!(.message, r'(?i)bad protocol version identification') ||
                  match!(.message, r'(?i)kex_exchange_identification.*connection (?:reset|closed)') ||
                  match!(.message, r'(?i)could not read protocol version') ||
                  match!(.message, r'(?i)invalid format') ||
                  match!(.message, r'(?i)connection (?:closed|reset).*authenticating.*\[preauth\]') ||
                  match!(.message, r'(?i)connection (?:closed|reset) by.*\[preauth\]') ||
                  match!(.message, r'(?i)Connection reset by authenticating') ||
                  match!(.message, r'(?i)no matching .* found') ||
                  match!(.message, r'(?i)unable to negotiate') ||
                  match!(.message, r'(?i)no(?: supported)? authentication methods available') ||
                  match!(.message, r'(?i)received disconnect.*no.*authentication methods') {
                    .meta.risk_level = "critical"
                    .meta.risk_type = "DDOS"
                }
              }
            }

            ########################################################################
            # No risk
            ########################################################################
            if .meta.risk_level == "unknown" && .message != null && .message != "" {
              if .meta.ip == "unknown" || 
                match!(.message, r'(?i)^accepted \w+') ||
                match!(.message, r'(?i)session opened for') ||
                match!(.message, r'(?i)server listening on') ||
                match!(.message, r'(?i)persourcepenalties logging rate-limited') ||
                match!(.message, r'(?i).* [preauth]') ||
                match!(.message, r'(?i)accepted key rsa .* found at .*') ||
                match!(.message, r'(?i)drop connection .* from') {
                  .meta.risk_level = "none"
              }
            }

            # Create reduced message by removing variable data
            if .message != null && .message != "" {
              reducedmessage = .message
              # reducedmessage = replace!(reducedmessage, r'user \w+', "user [USER]")
              reducedmessage = replace!(reducedmessage, r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', "[IP]")
              reducedmessage = replace(reducedmessage, r'port \d+', "port [PORT]")
              reducedmessage = replace(reducedmessage, r':\d+ ', ":[PORT] ")
              reducedmessage = replace(reducedmessage, r'pid = \d+', "pid = [PID]")
              reducedmessage = replace(reducedmessage, r'on pid \d+', "on pid [PID]")
              reducedmessage = replace(reducedmessage, r' \d+ connections', " [NB] connections")

              .meta.reducedmessage = to_string(.meta.risk_type) + " // " + reducedmessage
            } else {
              .meta.reducedmessage = ""
            }
          '';
        };

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
            .meta.user = "unknown"
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

            # Login fail
            if .message != null && .message != "" {
              if match!(.message, r'(?i)refused connection: .* SRC=')  {
                  .meta.risk_level = "critical"
                  .meta.risk_type = "Port scan"
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

        to_reaction = {
          type = "remap";
          inputs = [
            "sshd_cleaned"
            "iptables_cleaned"
          ];

          source = ''
            . = {
            "service": .service,
            "transport": .transport,
            "risk_level": .meta.risk_level,
            "risk_type": .meta.risk_type,
            "user": .meta.user,
            "ip": .meta.ip,
            # "reducedmessage": .meta.reducedmessage,
            # "message": .message,
            "timestamp": .timestamp,
            "unix_timestamp": .unix_timestamp
            }
          '';
        };
      };

      sinks = {
        ssh_reaction = {
          type = "file";
          inputs = [ "to_reaction" ];
          path = "/var/lib/vector/logs/reaction.logfmt";
          encoding = {
            codec = "logfmt";
          };
        };

        file_global = {
          type = "file";
          inputs = [
            "sshd_cleaned"
            "iptables_cleaned"
          ];
          path = "/var/lib/vector/logs/{{ transport }}-{{ service }}-risk-level-{{ meta.risk_level }}.log";
          encoding.codec = "json";
        };
      };
    };
  };
}
