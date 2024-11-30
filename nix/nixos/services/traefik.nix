{ lib, config, ... }:
let domain = config.homelab.domain;
in {
  networking.nftables.enable = true;
  networking.firewall = {
    interfaces = {
      br-adm = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ ];
      };
      br-dmz = {
        allowedTCPPorts = [ 80 443 ];
        allowedUDPPorts = [ ];
      };
    };

    # Forward
    # filterForward = true;
    # extraForwardRules = "iifname brdmz oifname brdmz accept";
    # extraForwardRules = "accept";
    # extraInputRules = "iifname brdmz accept";
    # extraInputRules = "accept";
    # "iifname brdmz ip saddr 192.168.254.0/24 ip daddr 192.168.253.0/24 accept";
  };

  # services.resolved.enable = true;

  # Enable Traefik
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      api.dashboard = true;
      api.insecure = true;

      # Enable logs
      # log.filePath = "/var/log/traefik/traefik.log";
      # accessLog.filePath = "/var/log/traefik/accessLog.log";

      # Enable Docker provider
      # providers.docker = {
      #   endpoint = "unix:///run/docker.sock";
      #   watch = true;
      #   exposedByDefault = false;
      # };

      # Configure entrypoints, i.e the ports
      entryPoints = {
        websecure.address = ":443";
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
      };

      # Configure certification
      certificatesResolvers.acme-challenge.acme = {
        email = "brunoadele@gmail.com";
        storage = "/var/lib/traefik/acme.json";
        httpChallenge.entryPoint = "web";
      };
    };

    # Dashboard
    dynamicConfigOptions.http.routers.dashboard = {
      rule = lib.mkDefault "Host(`traefik.${domain}`)";
      service = "api@internal";
      entryPoints = [ "websecure" ];
      tls = lib.mkDefault false;
      # Add certification
      # tls.certResolver = "acme-challenge";
    };
  };
}
