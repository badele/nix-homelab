{ lib, config, ... }:
let
  domain = config.homelab.domain;
  # aliasIps = lib.flatten (lib.mapAttrsToList (name: host:
  #   let alias = lib.optionals (host.dnsalias != null) host.dnsalias;
  #   in map (entry: {
  #     name = entry;
  #     ip = host.ipv4;
  #   }) alias) config.homelab.hosts);

in
{
  networking.firewall.enable = true;
  networking.firewall.logRefusedPackets = true;
  networking.firewall.logReversePathDrops = true;
  networking.firewall.logRefusedConnections = true;

  networking.nftables.enable = true;

  networking = {
    networkmanager.enable = true;

    domain = domain;
    enableIPv6 = false;

    # add an entry to /etc/hosts for each host
    # extraHosts = ''
    #   127.0.0.1 cert.adele.im
    #
    #   # ADM
    #   192.168.240.16 traefik.adele.im home.adele.im adguard.adele.im
    #
    #   # Hosts
    #   ${lib.concatStringsSep "\n" (lib.mapAttrsToList (hostname: hostinfo:
    #     "${hostinfo.ipv4} ${hostname}.${domain} ${hostname}")
    #     config.homelab.hosts)}
    #
    #   # Alias
    #   ${lib.concatMapStringsSep "\n"
    #   (host: "${host.ip} ${host.name}.${domain} ${host.name}") aliasIps}
    # '';

    # For ZFS
    hostId = "9cd5e8c7";
  };
}
