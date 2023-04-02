{ config, lib, pkgs, ... }:
let
  domain = config.homelab.domain;

  # For reduce smartphone battery utilization, disable ping
  noPing = [
    "Android"
    "Iphone"
  ];
  toPing = lib.filterAttrs (hostname: hostinfo: !lib.elem hostinfo.os noPing) config.homelab.hosts;

in
{
  services.prometheus.exporters.smokeping = {
    enable = true;
    hosts =
      (lib.mapAttrsToList
        (hostname: hostinfo:
          "${hostname}.${domain}")
        toPing) ++
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
