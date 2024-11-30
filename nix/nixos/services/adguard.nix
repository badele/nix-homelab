{ lib, config, ... }:
let
  webport = "3000";

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (name: host: {
      domain = name;
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
          domain = entry;
          answer = host.ipv4;
        })
        alias)
    config.homelab.hosts);
in
{
  # networking.nftables.enable = true;
  # networking.firewall = {
  #   interfaces = {
  #     br-adm = {
  #       allowedTCPPorts = [ 80 443 ];
  #       allowedUDPPorts = [ 53 ];
  #     };
  #     br-dmz = {
  #       allowedTCPPorts = [ ];
  #       allowedUDPPorts = [ 53 ];
  #     };
  #   };
  # };
  networking = {
    useDHCP = lib.mkForce true;
    firewall = {
      enable = false;
      allowedTCPPorts = [ 80 ];
    };
  };

  services.resolved.enable = false;
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      http.address = "0.0.0.0:${webport}";
      schema_version = 29;
      dns = {
        ratelimit = 0;
        bind_hosts = [ "0.0.0.0" ];
        bootstrap_dns = [ "9.9.9.10" "149.112.112.10" ];
        upstream_dns = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
        rewrites = hostsIps ++ aliasIps;
      };
    };
  };
}
