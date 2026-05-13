{ lib, config, ... }:
let
  roleName = "loki";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
  port_promtail = 3031;
in
lib.mkIf (roleEnabled) {

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
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "pihole";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };

  services.caddy.virtualHosts."promtail.${config.homelab.domain}" = {
    logFormat = ''
      output file /var/log/caddy/public.log {
        mode 0644
      }
      format json
    '';
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port_promtail}
    '';
  };

}
