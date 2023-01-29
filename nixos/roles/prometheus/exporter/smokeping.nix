{ config, lib, pkgs, ... }:
let
  domain = config.homelab.domain;
in
{
  services.prometheus.exporters.smokeping = {
    enable = true;
    hosts =
      (lib.mapAttrsToList
        (hostname: hostinfo:
          "${hostname}.${domain}")
        config.homelab.hosts) ++
      [
        "www.google.fr"
        "www.github.com"
      ];
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "smokeping";
      honor_labels = true;
      static_configs = [{
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smokeping.port}" ];
      }];
    }
  ];
}
