{ config, lib, ... }:
let domain = config.homelab.domain;
in {
  sops.secrets = {
    "services/netbox/secret" = {
      mode = "0400";
      owner = "netbox";
    };
  };

  services.netbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 8001;
    secretKeyFile = config.sops.secrets."services/netbox/secret".path;
  };

  services.nginx = {
    enable = true;
    group = "netbox";
    virtualHosts."netbox-static" = {
      listen = [{
        addr = "127.0.0.1";
        port = 9001;
      }];
      locations."/" = { root = "${config.services.netbox.dataDir}"; };
    };
  };

  services.traefik = {
    dynamicConfigOptions.http = {
      routers = {
        netbox = {
          rule =
            lib.mkDefault "Host(`netbox.${domain}`) && !PathPrefix(`/static`)";
          service = "netbox";
          entryPoints = [ "local" ];
        };
        "netbox-static" = {
          rule = "Host(`netbox.${domain}`) && PathPrefix(`/static`)";
          service = "netbox-static";
          entryPoints = [ "local" ];
        };
      };

      services = {
        netbox = {
          loadBalancer = { servers = [{ url = "http://localhost:8001"; }]; };
        };
        "netbox-static" = {
          loadBalancer.servers = [{ url = "http://127.0.0.1:9001"; }];
        };
      };
    };
  };
}
