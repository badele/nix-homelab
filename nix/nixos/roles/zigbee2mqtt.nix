{ outputs, lib, config, ... }:
let
  roleName = "zigbee2mqtt";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "zigbee2mqtt";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.dnsalias);
  cfg = config.services.zigbee2mqtt;
  mqtt_port = 1883;
in
lib.mkIf (roleEnabled)
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0451", ATTRS{idProduct}=="16a8", SYMLINK+="cc2531", MODE="0660", GROUP="zigbee2mqtt"
  '';

  systemd.services."zigbee2mqtt.service".requires = [ "mosquitto.service" ];
  systemd.services."zigbee2mqtt.service".after = [ "mosquitto.service" ];

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      availability = true;
      permit_join = true;
      serial.port = "/dev/cc2531";

      mqtt.server = "mqtt://mqtt.adele.im/${toString mqtt_port}";
      mqtt.user = "zigbee2mqtt";

      frontend.port = 8080;
    };
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined "No `${alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

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
  };

}
