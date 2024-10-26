{ outputs, lib, config, ... }:
let
  roleName = "mosquitto";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "mqtt";
  #aliasdefined = !(builtins.elem alias config.homelab.currentHost.dnsalias);
  cfg = config.services.mosquitto;
  port = 1883; # Default Mosquitto port
in
lib.mkIf (roleEnabled)
{
  # Configure sops secret
  sops.secrets."mqtt/pass/zigbee2mqtt" = { owner = "mosquitto"; group = "mosquitto"; };
  sops.secrets."mqtt/pass/hass" = { owner = "mosquitto"; group = "mosquitto"; };


  networking.firewall.allowedTCPPorts = [
    port
    80
    443
  ];

  services.mosquitto = {
    enable = true;

    listeners = [{
      inherit port;
      address = "0.0.0.0";
      settings.allow_anonymous = true;
      omitPasswordAuth = false;
      acl = [ "topic readwrite #" ];

      users.hass = {
        acl = [
          "readwrite #"
        ];
        passwordFile = config.sops.secrets."mqtt/pass/hass".path;
      };

      users."${config.services.zigbee2mqtt.settings.mqtt.user}" = {
        acl = [
          "readwrite #"
        ];
        passwordFile = config.sops.secrets."mqtt/pass/zigbee2mqtt".path;
      };

    }];
  };
}
