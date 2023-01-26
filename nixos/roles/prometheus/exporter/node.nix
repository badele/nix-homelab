{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];


  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "arp"
          "dmi"
          "hwmon"
          "cpu"
          "diskstats"
          "ethtool"
          "interrupts"
          "ksmd"
          "lnstat"
          "logind"
          "mountstats"
          "network_route"
          "ntp"
          "perf"
          "processes"
          "systemd"
          "tcpstat"
          "zfs"
        ];
      };
    };
  };
  services.prometheus.scrapeConfigs = [
    {
      job_name = "node";
      scrape_interval = "10s";
      static_configs = [
        {
          targets = [
            "bootstore:${toString config.services.prometheus.exporters.node.port}"
          ];
          labels = {
            alias = "bootstore";
          };
        }
        {
          targets = [
            "rpi40:${toString config.services.prometheus.exporters.node.port}"
          ];
          labels = {
            alias = "rpi40";
          };
        }
      ];
    }
  ];
}
