{ inputs, lib, config, pkgs, ... }:
let

  modName = "coredns";
  modEnabled = builtins.elem modName config.networking.homelab.currentHost.modules;
  myhost = config.networking.homelab.currentHost;
  domain = config.networking.homelab.domain;

  # Function compute DNS IP host
  hostlist = lib.mapAttrs
    (hostkey: hostinfo:
      {
        A = [ "${hostinfo.ipv4}" ];
      }
    )
    config.networking.homelab.hosts;

  adele-lan-zone = with inputs.dns.lib.combinators;
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
      subdomains = hostlist // rec {
        ns1 = {
          A = [ "${myhost.ipv4}" ];
        };
      };
    };

in
lib.mkIf (modEnabled)
{
  environment.etc."coredns/db.${domain}".text = inputs.dns.lib.toString "${domain}" adele-lan-zone;

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
