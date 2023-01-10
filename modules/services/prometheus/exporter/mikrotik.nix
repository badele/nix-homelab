{ config, ... }:
{
  sops.secrets."mikrotik-exporter-router-int-conf" = {
    owner = "prometheus";
  };

  services.prometheus = {
    exporters = {
      mikrotik = {
        enable = true;
        configFile = config.sops.secrets."mikrotik-exporter-router-int-conf".path;
      };
    };
  };
}
