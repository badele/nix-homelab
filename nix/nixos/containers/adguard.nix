# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ lib, config, pkgs, containerIpSuffix, ... }:
let

  webport = "3000";

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (name: host: {
      domain = "${name}.${config.homelab.domain}";
      answer = host.ipv4;
    })
    config.homelab.hosts;

  # Function
  # Get Alias IP
  aliasIps = lib.flatten (lib.mapAttrsToList
    (name: host:
      let alias = lib.optionals (host.dnsalias != null) host.dnsalias;
      in map
        (entry: {
          domain = "${entry}.${config.homelab.domain}";
          answer = host.ipv4;
        })
        alias)
    config.homelab.hosts);

in
{
  nixunits = {
    adguard = {
      autoStart = true;

      network = {
        hostIp4 = "192.168.240.${containerIpSuffix}";
        ip4 = "192.168.241.${containerIpSuffix}";
        ip4route = "192.168.240.${containerIpSuffix}";
      };

      config = {

        # environment.systemPackages = with pkgs; [ ];

        services.adguardhome = {
          enable = true;
          mutableSettings = false;
          settings = {
            http.address = "0.0.0.0:${webport}";
            schema_version = 29;
            dns = {
              enable_dnssec = true;
              ratelimit = 0;
              bind_hosts = [ "0.0.0.0" ];
              # https://www.quad9.net/fr/service/service-addresses-and-features
              bootstrap_dns = [ "9.9.9.11" "149.112.112.11" ];
              upstream_dns =
                [ "https://dns11.quad9.net/dns-query" "tls://dns11.quad9.net" ];
            };
            filtering = { rewrites = hostsIps ++ aliasIps; };
          };
        };
      };
    };
  };
}
