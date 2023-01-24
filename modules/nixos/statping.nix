{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.statping;
  aliasdefined = !(builtins.elem cfg.alias config.homelab.currentHost.alias);
  cert = (import ../../nixos/modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
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
    warnings =
      lib.optional aliasdefined "No `${cfg.alias}` alias defined in alias section ${config.networking.hostName}.alias [ ${toString config.homelab.currentHost.alias} ] in `homelab.json` file";

    networking.firewall.allowedTCPPorts = [
      cfg.port
      80
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

    # Nginx reverses proxy
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.alias}.${config.homelab.domain}" = {
      addSSL = true;
      sslCertificate = cert;
      sslCertificateKey = config.sops.secrets."wildcard-domain.key.pem".path;

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
