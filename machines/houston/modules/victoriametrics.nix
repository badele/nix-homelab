{
  config,
  pkgs,
  ...
}:
let
  victoria_addr = "127.0.0.1:8428";
in
{

  ############################################################################
  # victoriametrics
  ############################################################################

  services.victoriametrics = {
    enable = true;

    # webui and prometheus remote write endpoint
    listenAddress = victoria_addr;

    retentionPeriod = "100y";

    # Scrap values from itself every 5s
    extraOptions = [
      "-selfScrapeInterval=5s"
    ];

  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "cpu"
      "meminfo"
      "diskstats"
      "filesystem"
      "loadavg"
      "netdev"
      "systemd"
    ];
    listenAddress = "127.0.0.1";
    port = 9100;
  };

  services.vmagent = {
    enable = true;

    remoteWrite.url = "http://${victoria_addr}/api/v1/write";

    prometheusConfig = {
      scrape_configs = [
        {
          job_name = "node-exporter";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:9100" ];
              labels.type = "node-exporter";
            }
          ];
        }
        {
          job_name = "telegraf-exporter";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:9273" ];
              labels.type = "telegraf";
            }
          ];
        }
      ];
    };
  };

  ############################################################################
  # victorialogs
  ############################################################################
  services.victorialogs.enable = true;

}
