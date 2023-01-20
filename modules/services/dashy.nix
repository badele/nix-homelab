{ config, lib, pkgs, ... }:
let
  modName = "coredns";
  modEnabled = builtins.elem modName config.homelab.currentHost.modules;
  alias = "homelab";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.alias);
  cert = (import ../../modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
  port_dashy = 8081;

  settings = {
    pageInfo = {
      title = "Homelab";
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
      iconSize = "large";
      language = "fr";
      statusCheck = true;
      hideComponents.hideSettings = false;

      # Todo: fix this and remove statusCheckUrl
      statusCheckAllowInsecure = true;
    };
    sections = [
      {
        name = "Monitoring";
        items = [
          {
            title = "Grafana";
            url = "https://grafana.h";
            statusCheckUrl = "http://grafana.h";
            icon = "hl-grafana";
          }
          {
            title = "Prometheus";
            url = "https://prometheus.h";
            statusCheckUrl = "http://prometheus.h";
            icon = "hl-prometheus";
          }
          {
            title = "Smokeping";
            url = "https://smokeping.h";
            statusCheckUrl = "http://smokeping.h";
            icon = "hl-smokeping";
          }
          {
            title = "Loki";
            url = "https://loki.h/services";
            statusCheckUrl = "http://loki.h/services";
            icon = "hl-loki";
          }
        ];
      }
      {
        name = "Nix";
        items = [
          {
            title = "Fake site down";
            url = "https://fakesitedown.com";
            statusCheckUrl = "https://downdetector.fr/fakesitedown";
            icon = "hl-fail";
          }
          rec {
            title = "nix-cache";
            url = "https://nixcache.h//nix-cache-info";
            statusCheckUrl = "http://nixcache.h:5000/nix-cache-info";
            icon = "https://camo.githubusercontent.com/33a99d1ffcc8b23014fd5f6dd6bfad0f8923d44d61bdd2aad05f010ed8d14cb4/68747470733a2f2f6e69786f732e6f72672f6c6f676f2f6e69786f732d6c6f676f2d6f6e6c792d68697265732e706e67";
          }
        ];
      }
      {
        name = "Tools";
        items = [
          {
            title = "Google";
            url = "https://www.google.fr";
            icon = "hl-google";
          }
          {
            title = "Github";
            url = "https://github.com/badele";
            icon = "hl-github";
          }
        ];
      }
    ];
  };
in
lib.mkIf (modEnabled)
{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    storageDriver = "zfs";
  };

  networking.firewall.allowedTCPPorts = [
    port_dashy
    80
  ];

  services.dashy = {
    enable = true;
    imageTag = "2.1.1";
    port = port_dashy;
    inherit settings;
    extraOptions = [
      "--label"
      "traefik.http.routers.dashy.rule=Host(`dash.h`)"
      "--label"
      "traefik.http.services.dashy.loadBalancer.server.port=${toString port_dashy}"
      "--network=host"
      "--no-healthcheck"
    ];
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined "No `${alias}` alias defined in alias section ${config.networking.hostName}.alias [ ${toString config.homelab.currentHost.alias} ] in `homelab.json` file";

  services.nginx.enable = true;
  services.nginx.virtualHosts."${alias}.${config.homelab.domain}" = {
    addSSL = true;
    sslCertificate = cert;
    sslCertificateKey = config.sops.secrets."wildcard-domain.key.pem".path;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port_dashy};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };

}
