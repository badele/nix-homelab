{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.statping;
  aliasdefined = !(builtins.elem cfg.alias config.homelab.currentHost.dnsalias);
in
{
  options.services.statping = {
    enable = mkEnableOption "statping";
    imageTag = mkOption {
      type = types.str;
    };
    alias = mkOption {
      type = types.str;
      default = "statping";
    };
    dns = mkOption {
      type = types.str;
      default = config.homelab.currentHost.ipv4;
    };
    port = mkOption {
      type = types.int;
      default = 8082;
    };
    settings = mkOption {
      type = types.attrs;
    };
    extraOptions = mkOption { };
  };

  # docker-statping.service
  config = mkIf cfg.enable {

    # Check if host alias is defined in homelab.json alias section
    warnings = lib.optional aliasdefined "No `${cfg.alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

    networking.firewall.allowedTCPPorts = [
      cfg.port
      80
      443
    ];

    # statping docker service
    virtualisation.oci-containers.containers = {
      statping = {
        image = "adamboutcher/statping-ng:${cfg.imageTag}";
        inherit (cfg) extraOptions;
        environment = {
          TZ = "${config.time.timeZone}";
        };
      };
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.alias}.${config.homelab.domain}" = {
      logFormat = ''
        output file /var/log/caddy/public.log {
          mode 0644
        }
        format json
      '';
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
