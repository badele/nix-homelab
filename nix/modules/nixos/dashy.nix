{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dashy;
  aliasdefined = !(builtins.elem cfg.alias config.homelab.currentHost.dnsalias);
  configFile = pkgs.runCommand "conf.yml"
    {
      buildInputs = [ pkgs.yj ];
      preferLocalBuild = true;
    } ''
    yj -jy < ${pkgs.writeText "config.json" (builtins.toJSON cfg.settings)} > $out
  '';
in
{
  options.services.dashy = {
    enable = mkEnableOption "dashy";
    imageTag = mkOption {
      type = types.str;
    };
    alias = mkOption {
      type = types.str;
      default = "home";
    };
    port = mkOption {
      type = types.int;
      default = 8081;
    };
    settings = mkOption {
      type = types.attrs;
    };
    extraOptions = mkOption { };
  };

  # docker-dashy.service
  config = mkIf cfg.enable {

    # Check if host alias is defined in homelab.json alias section
    warnings =
      lib.optional aliasdefined "No `${cfg.alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

    networking.firewall.allowedTCPPorts = [
      cfg.port
      80
      443
    ];

    # Dashy docker service
    virtualisation.oci-containers.containers = {
      dashy = {
        image = "lissy93/dashy:${cfg.imageTag}";
        inherit (cfg) extraOptions;
        environment = {
          TZ = "${config.time.timeZone}";
        };
        volumes = [
          "${configFile}:/app/public/conf.yml"
        ];
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
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };

}
