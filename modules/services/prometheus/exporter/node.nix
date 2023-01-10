{ ... }:
{
  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
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
        ];
      };
    };
  };
}
