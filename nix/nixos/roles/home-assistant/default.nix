{ config, lib, pkgs, ... }:
let
  hass_port = 8123;
  hass_version = "2023.2.4";
  roleName = "home-assistant";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
  # Hass config
  hass_config = pkgs.writeText "configuration.yaml" ''
    # Discovery
    default_config:

    # Web Server configuration
    http:
      server_host: 127.0.0.1
      use_x_forwarded_for: true
      trusted_proxies: 127.0.0.1


    # Home configuration
    homeassistant:
      name: Home
      elevation: 50
      latitude: !secret home_lat
      longitude: !secret home_lon
      unit_system: metric
      country: FR
      time_zone: Europe/Paris

    logger:
      default: warning
      logs:
        homeassistant.components.rfxtrx: debug
        RFXtrx: debug
  '';

in
lib.mkIf (roleEnabled)
{

  sops.secrets."home-assistant" = {
    restartUnits = [ "home-assistant.service" ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Dashy docker service
  virtualisation.oci-containers.containers = {
    hass = {
      image = "ghcr.io/home-assistant/home-assistant:${hass_version}";
      environment = {
        TZ = "${config.time.timeZone}";
      };
      volumes = [
        "/data/docker/hass:/config"
        "${hass_config}:/config/configuration.yaml"
        "/run/secrets/home-assistant:/config/secrets.yaml"
      ];
      extraOptions = [
        "--device=/dev/ttyUSB0"
        "--device=/dev/ttyUSB1"
        "--network=host"
        "--privileged"
      ];
    };
  };

  # Nginx reverses proxy
  services.nginx.enable = true;
  services.nginx.virtualHosts."hass.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString hass_port};
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   Host $host;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_buffering off;
      '';
    };
  };
}









# services.home-assistant = {
# enable = roleEnabled;

# extraComponents = [
# "backup"
# "file_upload"
# "met"
# "mqtt"
# "sun"

# # Medias
# "cast"
# "spotify"
# "radio_browser"

# "hue"
# "tuya"
# "rfxtrx"

# "openweathermap"

# "cpuspeed"
# "fail2ban"
# "ffmpeg"
# "hddtemp"
# "shopping_list"

# ];

# extraPackages = python3Packages: with python3Packages; [
# netdisco # For discovery
# securetar # For backup
# pushover-complete
# accuweather
# ];

# # Minimal configuration
# # All configuration on the home-assistant directely
# # Saved to /var/lib/hass/.storage
# config = {
# default_config = { };

# # Web Server configuration
# http = {
# server_host = "127.0.0.1";
# use_x_forwarded_for = true;
# trusted_proxies = [ "127.0.0.1" ];
# };

# # Home configuration
# homeassistant = {
# name = "Home";
# elevation = 50;
# latitude = "!secret home_lat";
# longitude = "!secret home_lon";
# unit_system = "metric";
# country = "FR";
# time_zone = "Europe/Paris";
# };

# "automation ui" = "!include automations.yaml";

# frontend = { };
# history = { };
# prometheus = { };
# sensor = [ ];
# };
# };

# services.nginx.enable = true;
# services.nginx.virtualHosts."hass.${config.homelab.domain}" = {
# # Use wildcard domain
# useACMEHost = config.homelab.domain;
# forceSSL = true;

# locations."/" = {
# extraConfig = ''
#         proxy_pass http://127.0.0.1:${toString cfg.config.http.server_port};
#         proxy_set_header Host $host;
#         proxy_set_header Upgrade $http_upgrade;
#         proxy_set_header Connection $connection_upgrade;
#       '';
# };
# };
