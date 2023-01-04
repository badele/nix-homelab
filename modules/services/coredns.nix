{ inputs, lib, config, pkgs, ... }:
let

  modName = "coredns";
  modEnabled = builtins.elem modName config.homelab.currentHost.modules;
  cfghosts = config.homelab.hosts;
  myhost = config.homelab.currentHost;
  domain = config.homelab.domain;
  ttl = 180;

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (
      name: host:
        {
          name = name;
          ip = host.ipv4;
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
                name = entry;
                ip = host.ipv4;
              })
              alias
        )

        cfghosts
    );

  fileZone = pkgs.writeText "h.zone" ''
    $ORIGIN ${domain}.
    @       IN SOA ns nomail (
            1         ; Version number
            60        ; Zone refresh interval
            30        ; Zone update retry timeout
            180       ; Zone TTL
            3600)     ; Negative response TTL
  
    h. IN NS ns.h.

    ns ${toString ttl} IN A ${myhost.ipv4}

    ; hosts
    ${lib.concatMapStringsSep "\n" (host: 
        "${host.name}.${domain}. ${toString ttl} IN A ${host.ip}")
      hostsIps}

    ; alias
    ${lib.concatMapStringsSep "\n" (host: 
        "${host.name}.${domain}. ${toString ttl} IN A ${host.ip}")
      aliasIps}
  '';
in
lib.mkIf (modEnabled)
{
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
          file ${fileZone}
          log
        }
    '';
}
