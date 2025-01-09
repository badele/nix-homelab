{ lib, config, lan_address, adm_address, dmz_address, ... }:
let domain = config.homelab.domain;
in {

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      api.dashboard = true;
      api.insecure = false;

      log = {
        level = "INFO";
        filePath = "/var/lib/traefik/traefik.log";
      };

      accessLog = { filePath = "/var/lib/traefik/access.log"; };

      # Configure entrypoints, i.e the ports
      entryPoints = {
        # LAN
        lansecure.address = "${lan_address}:443";
        lan = {
          address = "${lan_address}:80";
          http.redirections.entryPoint = {
            to = "lansecure";
            scheme = "https";
          };
        };

        # ADM
        admsecure.address = "${adm_address}:443";
        adm = {
          address = "${adm_address}:80";
          http.redirections.entryPoint = {
            to = "admsecure";
            scheme = "https";
          };
        };

        # DMZ
        dmzsecure.address = "${dmz_address}:443";
        dmz.address = "${dmz_address}:80";
      };

      # Configure certification
      certificatesResolvers.letsencrypt.acme = {
        email = "brunoadele@gmail.com";
        storage = "/var/lib/traefik/acme.json";
        httpChallenge.entryPoint = "dmz";
      };
    };

    # Dashboard
    dynamicConfigOptions.http = {
      routers = {
        #######################################################################
        # DMZ
        #######################################################################
        dmz-acme = {
          rule = "PathPrefix(`/.well-known/acme-challenge`)";
          service = "acme-http@internal";
          entryPoints = "dmz";
        };

        dmz-deny = {
          rule = "Host(`*`)";
          service = "deny-service";
        };

        #######################################################################
        # ADM
        #######################################################################
        dashboard = {
          rule = lib.mkDefault "Host(`traefik.${domain}`)";
          service = "api@internal";
          entryPoints = [ "admsecure" ];
          tls.certresolver = "letsencrypt";

        };
        homepages = {
          rule = lib.mkDefault "Host(`home.${domain}`)";
          service = "homepage";
          entryPoints = [ "admsecure" ];
          tls.certresolver = "letsencrypt";
        };
        adguard = {
          rule = lib.mkDefault "Host(`adguard.${domain}`)";
          service = "adguard";
          entryPoints = [ "admsecure" ];
          tls.certresolver = "letsencrypt";
        };
        note = {
          rule = lib.mkDefault "Host(`note.${domain}`)";
          service = "trilium";
          entryPoints = [ "admsecure" ];
          tls.certresolver = "letsencrypt";
        };
      };

      services = {
        #######################################################################
        # DMZ
        #######################################################################
        deny-service = {
          loadBalancer = { servers = [{ url = "http://127.0.0.1:65535"; }]; };
        };

        #######################################################################
        # ADM
        #######################################################################
        adguard = {
          loadBalancer = {
            servers = [{ url = "http://192.168.241.97:3000"; }];
          };
        };
        homepage = {
          loadBalancer = {
            servers = [{ url = "http://192.168.241.98:8082"; }];
          };
        };
        trilium = {
          loadBalancer = {
            servers = [{ url = "http://192.168.241.99:8080"; }];
          };
        };
      };
    };
  };
}
