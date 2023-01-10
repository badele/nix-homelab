{ config, lib, ... }:
let
  modName = "prometheus";
  modEnabled = builtins.elem modName config.homelab.currentHost.modules;
  port_prometheus = 9090;
  cert = (import ../../../modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
in
lib.mkIf (modEnabled)
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
              "bootstore:9100"
            ];
            labels = {
              alias = "bootstore";
            };
          }
          {
            targets = [
              "rpi40:9100"
            ];
            labels = {
              alias = "rpi40";
            };
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
  services.nginx.virtualHosts."${modName}.${config.homelab.domain}" = {
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
