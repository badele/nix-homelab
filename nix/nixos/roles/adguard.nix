{ outputs, lib, config, ... }:
let
  roleName = "adguard";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "dns";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.dnsalias);
  cfg = config.services.adguardhome;

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (
      name: host:
        {
          domain = name;
          answer = host.ipv4;
        }
    )
    config.homelab.hosts;

  # Function
  # Get Alias IP
  aliasIps = lib.flatten
    (

      lib.mapAttrsToList
        (
          name: host:
            let
              alias = lib.optionals (host.dnsalias != null) host.dnsalias;
            in
            map
              (entry: {
                domain = entry;
                answer = host.ipv4;
              })
              alias
        )
        config.homelab.hosts
    );
in
lib.mkIf (roleEnabled)
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.allowedUDPPorts = [
    53
  ];

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      bind_host = "0.0.0.0";
      bind_port = 3002;
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
        upstream_dns = [
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
          "8.8.4.4"
        ];
        rewrites = hostsIps ++ aliasIps;
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
        proxy_pass http://127.0.0.1:${toString cfg.settings.bind_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
