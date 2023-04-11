{ config, lib, pkgs, ... }:
let
  roleName = "grafana";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;

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
lib.mkIf (roleEnabled)
{
  networking.firewall.allowedTCPPorts = [
    config.services.grafana.settings.server.http_port
    80
    443
  ];

  services.grafana = {
    enable = true;

    settings = {
      analytics.reporting_enabled = false;

      server = {
        domain = "${roleName}.${config.homelab.domain}";
        addr = "127.0.0.1";

      };
    };

    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.prometheus.port}";
      }
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
      }
    ];

    provision.dashboards.settings.providers = [{
      name = "default";
      options.path = grafana-dashboards;
    }];
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${roleName}.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString config.services.grafana.settings.server.http_port};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;      
      '';
    };
  };
}
