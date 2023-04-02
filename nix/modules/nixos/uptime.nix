{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.uptime;
  aliasdefined = !(builtins.elem cfg.alias config.homelab.currentHost.dnsalias);
in
{
  options.services.uptime = {
    enable = mkEnableOption "uptime";
    imageTag = mkOption {
      type = types.str;
    };
    alias = mkOption {
      type = types.str;
      default = "uptime";
    };
    dns = mkOption {
      type = types.str;
      default = config.homelab.currentHost.ipv4;
    };
    port = mkOption {
      type = types.int;
      default = 8083;
    };
    settings = mkOption {
      type = types.attrs;
    };
    extraOptions = mkOption { };
  };

  # docker-uptime.service
  config = mkIf cfg.enable {

    # Check if host alias is defined in homelab.json alias section
    warnings =
      lib.optional aliasdefined "No `${cfg.alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

    networking.firewall.allowedTCPPorts = [
      cfg.port
      80
    ];

    # uptime docker service
    virtualisation.oci-containers.containers = {
      uptime = {
        image = "louislam/uptime-kuma:${cfg.imageTag}";
        inherit (cfg) extraOptions;
        environment = {
          TZ = "${config.time.timeZone}";
        };
      };
    };

    # Nginx reverses proxy
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.alias}.${config.homelab.domain}" = {
      # Use wildcard domain
      useACMEHost = config.homelab.domain;
      forceSSL = true;

      locations."/" = {
        extraConfig = ''
          proxy_pass http://127.0.0.1:${toString cfg.port};
          proxy_set_header   X-Real-IP $remote_addr;
          proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header   Host $host;
          proxy_http_version 1.1;
          proxy_set_header   Upgrade $http_upgrade;
          proxy_set_header   Connection "upgrade";
        '';
      };
    };
  };
}
