{ config, lib, pkgs, ... }:
let
  cfg = config.services.dashy;
  roleName = "dashy";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;

  settings = {
    pageInfo = {
      title = "${config.homelab.domain} Homelab";
      description = "homelab made entirelly with nixos";
      navLinks = [
        {
          title = "GitHub";
          path = "https://github.com/badele/nix-homelab";
        }
      ];
    };
    appConfig = {
      theme = "nord-frost";
      layout = "auto";
      iconSize = "medium";
      language = "fr";
      statusCheck = true;
      hideComponents.hideSettings = false;
    };
    sections = [
      # !!!!!!!!!!!!!!!!!!!!!!!
      # You mush disable adblock browser
      # !!!!!!!!!!!!!!!!!!!!!!!
      {
        name = "Monitoring";
        icon = "fas fa-monitor-heart-rate";
        items = [
          {
            title = "Uptime";
            url = "https://uptime.${config.homelab.domain}";
            icon = "hl-uptime-kuma";
          }
          {
            title = "Statping";
            url = "https://statping.${config.homelab.domain}";
            icon = "hl-statping";
          }
          {
            title = "Grafana";
            url = "https://grafana.${config.homelab.domain}";
            icon = "hl-grafana";
          }
          {
            title = "Prometheus";
            url = "https://prometheus.${config.homelab.domain}";
            icon = "hl-prometheus";
          }
          {
            title = "Smokeping";
            url = "https://smokeping.${config.homelab.domain}";
            icon = "hl-smokeping";
          }
          {
            title = "Loki";
            url = "https://loki.${config.homelab.domain}/services";
            icon = "hl-loki";
          }
          {
            title = "nix-cache";
            url = "https://nixcache.${config.homelab.domain}/nix-cache-info";
            icon = "https://camo.githubusercontent.com/33a99d1ffcc8b23014fd5f6dd6bfad0f8923d44d61bdd2aad05f010ed8d14cb4/68747470733a2f2f6e69786f732e6f72672f6c6f676f2f6e69786f732d6c6f676f2d6f6e6c792d68697265732e706e67";
          }
          {
            title = "Home Assistant";
            url = "https://hass.${config.homelab.domain}";
            icon = "hl-home-assistant";
          }
          {
            title = "zigbee";
            url = "https://zigbee.${config.homelab.domain}";
            icon = "hl-mqtt";
          }
          {
            title = "adguard";
            url = "https://dns.${config.homelab.domain}";
            icon = "hl-adguard-home";
          }
        ];
      }
      {
        name = "Tools";
        icon = "fas fa-rocket";
        items = [
          {
            title = "mikrotik Livingroom";
            url = "http://192.168.254.254";
            icon = "hl-mikrotik";
          }
          {
            title = "mikrotik Bedroom";
            url = "http://192.168.254.253";
            icon = "hl-mikrotik";
          }
          {
            title = "mikrotik Office";
            url = "http://192.168.254.252";
            icon = "hl-mikrotik";
          }
        ];
      }
      {
        name = "Website";
        icon = "fas fa-bookmark";
        items = [
          {
            title = "Nix packages/Options";
            url = "https://search.nixos.org/packages";
            icon = "favicon";
          }
          {
            title = "Google";
            url = "https://www.google.fr";
            icon = "favicon";
          }
          {
            title = "Github";
            url = "https://github.com/badele";
            icon = "favicon";
          }
        ];
      }
    ];
  };
in
{

  imports = [
    ../../modules/nixos/dashy.nix # TODO: use nixosModules
    ../features/system/containers.nix
  ];

  services.dashy = {
    inherit settings;
    enable = roleEnabled;
    imageTag = "2.1.1";
    port = 8081;
    extraOptions = [
      "-p"
      "${toString cfg.port}:80"
    ];
  };
}
