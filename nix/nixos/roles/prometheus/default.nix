{ config, lib, pkgs, ... }:
let
  roleName = "prometheus";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
  cfg = config.services.prometheus;
in
lib.mkIf (roleEnabled)
{

  # TODO: sub level sops section `alertmanager/env`
  sops.secrets.alertmanager = { };

  services.prometheus = {
    enable = true;

    # TODO: generate dynamically from homelab.json
    scrapeConfigs = [
      {
        job_name = "prometheus";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString cfg.port}"
            ];
            labels = {
              alias = "prometheus";
            };
          }
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
            ];
            labels = {
              alias = "alertmanager";
            };
          }
        ];
      }
    ];

    # Test alertmanager
    # curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"myalert"}}]' http://127.0.0.1:9093/api/v1/alerts
    alertmanagers = [
      {
        scheme = "http";
        path_prefix = "/";
        static_configs = [{ targets = [ "127.0.0.1:${toString config.services.prometheus.alertmanager.port}" ]; }];
      }
    ];

    alertmanager = {
      enable = true;

      # Secret content all variables content
      # example:
      # alertmanager: |
      #  var_name1=value1
      #  var_name2=value2
      environmentFile = config.sops.secrets.alertmanager.path;
      extraFlags = [
        "--cluster.listen-address=" # disables HA mode
      ];

      # Converted to alertmanager.yml
      configuration = {
        receivers = [
          {
            name = "pushover";
            pushover_configs = [
              {
                send_resolved = true;
                user_key = "$PUSHOVER_USER_KEY";
                token = "$PUSHOVER_TOKEN";
              }
            ];
          }
        ];

        route = {
          receiver = "pushover";
          routes = [
            {
              group_wait = "30s";
              group_interval = "2m";
              repeat_interval = "4h";
              group_by = [ "alertname" "alias" ];
              receiver = "pushover";
            }
          ];
        };
      };
    };

    rules =
      let
        diskCritical = 10;
        diskWarning = 20;
      in
      [
        (builtins.toJSON {
          groups = [
            {
              name = "alerting-rules";
              rules = import ./alert-rules.nix { inherit lib; };
              # rules = [
              #   {
              #     alert = "SystemD_UnitDown";
              #     expr = ''node_systemd_unit_state{state="failed"} == 1'';
              #     annotations = {
              #       summary = "{{$labels.alias}} failed to (re)start the following service {{$labels.name}}.";
              #     };
              #   }
              #   {
              #     alert = "RootPartitionFull";
              #     for = "10m";
              #     expr = ''(node_filesystem_free_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"} < ${toString diskWarning}'';
              #     annotations = {
              #       summary = ''{{ $labels.job }} running out of space: {{ $value | printf "%.2f" }}% < ${toString diskWarning}%'';
              #     };
              #   }
              # ];
            }
          ];
        })
      ];
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${roleName}.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString cfg.port};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
      '';
    };
  };
}
