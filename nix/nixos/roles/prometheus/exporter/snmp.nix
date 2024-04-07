{ config, pkgs, ... }:
let

  snmpFile = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/8d096de7ce01bc6477fbaec3511d707836f744cd/snmp.yml";
    sha256 = "sha256:12zakhxcsgdh9c6idfr9kgy62gp5kjm8xm0zwdpkqnlilrmgndmz";
  };

  mikrotikMib =
    builtins.replaceStrings [
      "mikrotik:"
    ] [
      ''
        mikrotik:
          version: 2
          auth:
            community: public
      ''
    ]
      (builtins.readFile snmpFile);

  snmpConf = pkgs.writeText "snmp.yaml" ''
    ${mikrotikMib}
  '';

in
{
  services.prometheus = {
    exporters = {
      snmp = {
        enable = true;
        configurationPath = snmpConf;
      };
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "mikrotik";
      scrape_interval = "120s";
      scrape_timeout = "90s";
      metrics_path = "/snmp";
      params = {
        module = [ "mikrotik" ];
      };
      relabel_configs = [
        {
          "source_labels" = [ "__address__" ];
          "target_label" = "__param_target";
        }
        {
          "source_labels" = [ "__param_target" ];
          "target_label" = "instance";
        }
        {
          "target_label" = "__address__";
          "replacement" = "127.0.0.1:${toString config.services.prometheus.exporters.snmp.port}";
        }
      ];
      static_configs = [
        {
          targets = [
            "192.168.254.254"
            "192.168.254.253"
            "192.168.254.252"
          ];
        }
      ];
    }
  ];
}
