{
  lib,
  ...
}:
let
  iptablesRules = import ./rules/iptables.nix;
  nginxLogsRules = import ./rules/nginx_logs.nix;
  sshdRules = import ./rules/sshd.nix;
  victoriametrics = import ./rules/victoriametrics.nix;
in
{
  users.users.vector = {
    isSystemUser = true;
    group = "vector";
    extraGroups = [ "nginx" ];
  };
  users.groups.vector = { };

  systemd.services.vector.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "vector";
    Group = "vector";
  };

  # jq 'select(.meta.reducedmessage != null).meta.reducedmessage' /var/lib/vector/logs/*.risk-level-unknown.log | sort | uniq -c | sort -h
  services.vector = {
    enable = true;
    journaldAccess = true;

    settings = {
      data_dir = "/var/lib/vector";

      sources =
        sshdRules.sources // iptablesRules.sources // victoriametrics.sources // nginxLogsRules.sources;

      transforms =
        sshdRules.transforms
        // iptablesRules.transforms
        // victoriametrics.transforms
        // nginxLogsRules.transforms
        // {

          reaction_format = {
            type = "remap";
            inputs = [
              "sshd_cleaned"
              "iptables_cleaned"
              "nginx_logs_cleaned"
            ];

            source = ''
              . = {
              "service": .service,
              "transport": .transport,
              "risk_level": .meta.risk_level,
              "risk_type": .meta.risk_type,
              "data_type": .meta.data_type,
              "data_value": .meta.data_value,
              "ip": .meta.ip,
              # "reducedmessage": .meta.reducedmessage,
              # "message": .message,
              "timestamp": .timestamp,
              "unix_timestamp": .unix_timestamp
              }
            '';
          };

          critical_reaction = {
            type = "filter";
            inputs = [ "reaction_format" ];
            condition = ''
              .ip != "unknown" && .risk_level == "critical"
            '';
          };
        };

      sinks = victoriametrics.sinks // {
        log_to_reaction = {
          type = "file";
          inputs = [ "critical_reaction" ];
          path = "/var/lib/vector/logs/reaction.logfmt";
          encoding = {
            codec = "logfmt";
          };
        };

        file_nginx_sink = {
          type = "file";
          inputs = [
            "reaction_format"
          ];
          path = "/var/lib/vector/logs/reaction_format.json";
          encoding.codec = "json";
        };

        file_global = {
          type = "file";
          inputs = [
            "sshd_cleaned"
            "iptables_cleaned"
            "nginx_logs_cleaned"
          ];
          path = "/var/lib/vector/logs/{{ transport }}-{{ service }}-risk-level-{{ meta.risk_level }}.json";
          encoding.codec = "json";
        };
      };
    };
  };
}
