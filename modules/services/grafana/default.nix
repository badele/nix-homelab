{ config, lib, pkgs, ... }:
let
  modName = "grafana";
  modEnabled = builtins.elem modName config.homelab.currentHost.modules;
  cert = (import ../../../modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;

  port_grafana = 2342;
  port_loki = config.services.loki.configuration.server.http_listen_port;
  port_prometheus = config.services.prometheus.port;

  # Copy all json dashboard
  grafana-dashboards = pkgs.stdenv.mkDerivation {
    name = "grafana-dashboards";
    src = ./.;
    installPhase = ''
      mkdir -p $out/
      install -D -m755 $src/dashboards/*.json $out/
    '';
  };
in
lib.mkIf (modEnabled)
{
  sops.secrets."wildcard-domain.key.pem" = {
    owner = "${config.services.nginx.user}";
    mode = "0444";
    sopsFile = ../../../hosts/secrets.yml;
  };

  networking.firewall.allowedTCPPorts = [
    port_grafana
    443
    80
  ];

  services.grafana = {
    enable = true;

    settings = {
      analytics.reporting_enabled = false;

      server = {
        domain = "${modName}.${config.homelab.domain}";
        http_port = port_grafana;
        addr = "127.0.0.1";

      };
    };

    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString port_prometheus}";
      }
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:${toString port_loki}";
      }
    ];

    provision.dashboards.settings.providers = [{
      name = "default";
      options.path = grafana-dashboards;
    }];
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${modName}.${config.homelab.domain}" = {
    addSSL = true;
    sslCertificate = cert;
    sslCertificateKey = config.sops.secrets."wildcard-domain.key.pem".path;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port_grafana};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;      
      '';
    };
  };
}
