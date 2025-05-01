{ lib, config, ... }:
let
  domain = config.homelab.domain;
  localIp = config.homelab.currentHost.ipv4;
in
{

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      api.dashboard = true;
      api.insecure = false;

      log = {
        level = "DEBUG";
        filePath = "/var/lib/traefik/traefik.log";
      };

      accessLog = { filePath = "/var/lib/traefik/access.log"; };

      entryPoints = { local = { address = "${localIp}:80"; }; };
    };

    # Dashboard
    dynamicConfigOptions.http = {
      routers = {
        dashboard = {
          rule = lib.mkDefault "Host(`traefik.${domain}`)";
          service = "api@internal";
          entryPoints = [ "local" ];

        };
        jellyfin = {
          rule = lib.mkDefault "Host(`jellyfin.${domain}`)";
          service = "jellyfin";
          entryPoints = [ "local" ];
        };
        sonarr = {
          rule = lib.mkDefault "Host(`sonarr.${domain}`)";
          service = "sonarr";
          entryPoints = [ "local" ];
        };
        prowlarr = {
          rule = lib.mkDefault "Host(`prowlarr.${domain}`)";
          service = "prowlarr";
          entryPoints = [ "local" ];
        };
      };

      services = {
        jellyfin = {
          loadBalancer = { servers = [{ url = "http://localhost:8096"; }]; };
        };
        sonarr = {
          loadBalancer = { servers = [{ url = "http://localhost:8989"; }]; };
        };
        prowlarr = {
          loadBalancer = { servers = [{ url = "http://localhost:9696"; }]; };
        };
      };
    };
  };
}
