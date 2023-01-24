{ config, lib, pkgs, ... }:
let
  roleName = "prometheus";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
  port_prometheus = 9090;
  cert = (import ../../../nixos/modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
in
lib.mkIf (roleEnabled)
{

  networking.firewall.allowedTCPPorts = [
    port_prometheus
  ];

  services.prometheus = {
    port = port_prometheus;
    enable = true;

    # TODO: generate dynamically from homelab.json
    scrapeConfigs = [
      {
        job_name = "prometheus";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString port_prometheus}"
            ];
            labels = {
              alias = "prometheus";
            };
          }
        ];
      }
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
              "192.168.0.10"
            ];
          }
        ];

      }
      {
        job_name = "coredns";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "bootstore:9153"
            ];
            labels = {
              alias = "bootstore";
            };
          }
          {
            targets = [
              "rpi40:9153"
            ];
            labels = {
              alias = "rpi40";
            };
          }
        ];
      }
    ];
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${roleName}.${config.homelab.domain}" = {
    addSSL = true;
    sslCertificate = cert;
    sslCertificateKey = config.sops.secrets."wildcard-domain.key.pem".path;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port_prometheus};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;      
      '';
    };
  };
}
