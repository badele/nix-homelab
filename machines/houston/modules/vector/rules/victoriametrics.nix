let
  victoria_addr = "127.0.0.1:8428";
in
{
  sources = {
    # nginx = {
    #   type = "nginx_metrics";
    #   endpoints = [ "http://localhost/nginx_status" ];
    # };
  };

  transforms = {

    with_value_one = {
      type = "remap";
      inputs = [ "critical_reaction" ];
      source = ''
        .value = 1
      '';
    };

    vector_security_events = {
      type = "log_to_metric";
      inputs = [
        "with_value_one"
      ];
      metrics = [
        {
          type = "counter";
          field = "value";
          name = "vector_security_events";
          description = "Total number of security events";
          tags = {
            data_type = "{{ data_type }}";
            data_value = "{{ data_value }}";
            service = "{{ service }}";
            risk_level = "{{ risk_level }}";
            risk_type = "{{ risk_type }}";
          };
        }
      ];
    };
  };

  # job = victoria-metrics;
  sinks = {
    victoriametrics_sink = {
      type = "prometheus_remote_write";
      inputs = [
        "vector_security_events"
        # "security_events_total"
        # "security_risk_events"
        # "security_ip_events"
        # "security_critical_rate"
      ];
      endpoint = "http://${victoria_addr}/api/v1/write";

      batch.max_events = 1000;
      batch.timeout_secs = 15;

      healthcheck = {
        enabled = false;
      };
    };
  };
}
