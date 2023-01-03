{ inputs, lib, config, pkgs, ... }:
let

  modName = "coredns";
  modEnabled = builtins.elem modName config.networking.homelab.currentHost.modules;
  cfghosts = config.networking.homelab.hosts;
  myhost = config.networking.homelab.currentHost;
  domain = config.networking.homelab.domain;

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (
      name: host:
        {
          "${name}" = "${host.ipv4}";
        }
    )
    cfghosts;

  # Function
  # Get Alias IP
  aliasIps = lib.flatten
    (

      lib.mapAttrsToList
        (
          name: host:
            let
              alias = lib.optionals (host.alias != null) host.alias;
            in
            map
              (entry: {
                "${entry}" = "${host.ipv4}";
              })
              alias
        )

        cfghosts
    );

  # Merge host and alias
  allDnsEntries = hostsIps ++ aliasIps;

  # Group IP by same alias name
  groupByEntries = lib.foldAttrs
    (
      name: ip:
        [ name ] ++ ip
    )
    [ ];

  # Function compute DNS IP host
  convertToDNSEntry = lib.mapAttrs
    (
      name: ips:
        {
          "A" = ips;
        }
    );

  dnsConverted = convertToDNSEntry (groupByEntries allDnsEntries);

  lan-zone = with inputs.dns.lib.combinators;
    {
      SOA = {
        nameServer = "ns1";
        adminEmail = "brunoadele@gmail.com";
        serial = 2022122803;
        ttl = 300;
      };

      NS = [
        "ns1.${domain}."
      ];

      # Merge dict with // operator
      subdomains = dnsConverted // rec {
        ns1 = {
          A = [ "${myhost.ipv4}" ];
        };
      };
    };

in
lib.mkIf (modEnabled)
{

  environment.etc."coredns/db.${domain}".text = inputs.dns.lib.toString "${domain}" lan-zone;

  services.coredns.enable = true;
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
  services.coredns.config =
    ''
      . {
          forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
          cache
          log
        }


      ${domain} {
          file /etc/coredns/db.${domain}
          log
        }
    '';
}
