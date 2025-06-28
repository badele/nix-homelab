{ outputs, lib, config, ... }:
let
  roleName = "zigbee2mqtt";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "zigbee";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.dnsalias);
  cfg = config.services.zigbee2mqtt;
  mqtt_port = 1883;
in
lib.mkIf (roleEnabled)
{
  # Configure sops secret
  sops.secrets."mqtt/secret/zigbee2mqtt" = {
    path = "/var/lib/zigbee2mqtt/secret.yaml";
    owner = "${config.systemd.services.zigbee2mqtt.serviceConfig.User}";
    group = "${config.systemd.services.zigbee2mqtt.serviceConfig.Group}";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="sonoff_zigbee", MODE="0660", GROUP="zigbee2mqtt"
  '';

  systemd.services."zigbee2mqtt.service".requires = [ "mosquitto.service" ];
  systemd.services."zigbee2mqtt.service".after = [ "mosquitto.service" ];

  services.zigbee2mqtt = {
    enable = true;

    settings = {
      advanced = {
        log_level = "debug";
      };

      homeassistant = true;
      availability = true;
      permit_join = false;
      serial.port = "/dev/sonoff_zigbee";

      device_options = {
        retain = true;
      };

      mqtt = {
        server = "mqtt://mqtt.adele.lan/${toString mqtt_port}";
        user = "zigbee2mqtt";
        password = "!secret password";
      };

      frontend.port = 8080;

      devices = {
        # Desk
        "0x0017880109b265de" = { friendly_name = "homelab/zone/desk/left-light"; };
        "0x0017880109b265cb" = { friendly_name = "homelab/zone/desk/right-light"; };

        # TV zone
        "0x5c0272fffe2b8fa4" = { friendly_name = "homelab/zone/tv/ambientlight"; };
        "0x7cb03eaa0a003825" = { friendly_name = "homelab/zone/tv/light"; };

        # Terrace
        "0x60a423fffe429c2a" = { friendly_name = "homelab/zone/terrace/left-light"; };
        "0xbc33acfffe043e2f" = { friendly_name = "homelab/zone/terrace/right-light"; };
        "0x2c1165fffe81b0b0" = { friendly_name = "homelab/zone/terrace/motion-detection"; };

        # Laundry
        "0x00158d000638dd75" = { friendly_name = "homelab/zone/laundry/electric-power-monitor"; kWh_precision = 3; };
        "0xa4c138dd14376bc6" = { friendly_name = "homelab/zone/laundry/power-socket"; };

        # Bathroom
        "0xa4c13866cdd109b7" = { friendly_name = "homelab/zone/bathroom/washing-machine"; };
        "0xa4c1386feb7d8ddb" = { friendly_name = "homelab/zone/bathroom/clothes-dryer"; };

        # Btn
        "0x00158d0002134f4c" = {
          friendly_name = "homelab/zone/unknow/btn-aquara";
          legacy = false;
        };
      };


      groups = {
        "1" = {
          friendly_name = "homelab/group/desk/lights";
          devices = [
            "homelab/zone/desk/left-light"
            "homelab/zone/desk/right-light"
          ];
        };

        "2" = {
          friendly_name = "homelab/group/tv/lights";
          devices = [
            "homelab/zone/tv/ambientlight"
            "homelab/zone/tv/light"
          ];
        };

        "3" = {
          friendly_name = "homelab/group/terrace/lights";
          devices = [
            "homelab/zone/terrace/left-light"
            "homelab/zone/terrace/right-light"
          ];
        };
      };
    };
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined " No `${alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

  services.nginx.enable = true;
  services.nginx.virtualHosts."${alias}.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString cfg.settings.frontend.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };

    # Websocket
    locations."/api" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString cfg.settings.frontend.port}/api;
        proxy_set_header Host $host;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };
  };
}
