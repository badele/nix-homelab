{ config, lib, pkgs, ... }:
let
  cfg = config.services.home-assistant;
  roleName = "home-assistant";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
in
{

  imports = [
    ./blueprints
  ];

  sops.secrets."home-assistant" = {
    owner = "hass";
    path = "/var/lib/hass/secrets.yaml";
    restartUnits = [ "home-assistant.service" ];
  };

  networking.firewall.allowedTCPPorts = [
    cfg.config.http.server_port
    443
    80
  ];

  services.home-assistant = {
    enable = roleEnabled;

    extraComponents = [
      "backup"
      "file_upload"
      "met"
      "mqtt"
      "sun"

      # Medias
      "cast"
      "spotify"
      "radio_browser"

      "hue"
      "tuya"
      "rfxtrx"

      "openweathermap"

      "cpuspeed"
      "fail2ban"
      "ffmpeg"
      "hddtemp"
      "shopping_list"

    ];

    extraPackages = python3Packages: with python3Packages; [
      netdisco # For discovery
      securetar # For backup
      pushover-complete
      accuweather
    ];

    # Minimal configuration
    # All configuration on the home-assistant directely
    # Saved to /var/lib/hass/.storage
    config = {
      default_config = { };

      # Web Server configuration
      http = {
        server_host = "127.0.0.1";
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };

      # Home configuration
      homeassistant = {
        name = "Home";
        elevation = 50;
        latitude = "!secret home_lat";
        longitude = "!secret home_lon";
        unit_system = "metric";
        country = "FR";
        time_zone = "Europe/Paris";
      };

      "automation ui" = "!include automations.yaml";

      frontend = { };
      history = { };
      prometheus = { };
      sensor = [ ];
    };
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."hass.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString cfg.config.http.server_port};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;      
      '';
    };
  };
}
