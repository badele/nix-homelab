{ cfg, sinkInputs, ... }:
{
  sources = { };
  transforms = { };

  sinks = {
    victorialogs_sink = {
      type = "elasticsearch";
      inputs = sinkInputs;
      endpoints = [ cfg.victorialogs.endpoint ];
      mode = "bulk";
      api_version = "v8";
      healthcheck.enabled = false;
      query = {
        _msg_field = "message";
        _time_field = "timestamp";
        _stream_fields = "service,source_host,app_name";
      };
    };
  };
}
