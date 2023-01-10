{ lib, config, ... }:
let
  modName = "promtail";
  port_promtail = 3031;
  cert = (import ../../../modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
in
{

  networking.firewall.allowedTCPPorts = [
    port_promtail
  ];

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = port_promtail;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "pihole";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${modName}.${config.homelab.domain}" = {
    addSSL = true;
    sslCertificate = cert;
    sslCertificateKey = config.sops.secrets."wildcard-domain.key.pem".path;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port_promtail};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;      
      '';
    };
  };

}
