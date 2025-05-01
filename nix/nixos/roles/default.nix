{ pkgs, lib, config, ... }: {
  imports = [
    #    ./loki/promtail.nix
    ./acme.nix
    ./adguard.nix
    ./coredns.nix
    # ./dashy.nix
    ./grafana
    ./home-assistant
    ./loki/loki.nix
    ./mosquitto.nix
    ./nfs.nix
    ./nix-serve.nix
    ./ntp.nix
    ./prometheus
    ./smokeping.nix
    ./statping.nix
    ./uptime.nix
    ./virtualization.nix
    ./zigbee2mqtt.nix
  ];
}
