{ lib, config, pkgs, ... }:
let
  roleName = "coredns";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
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
                name = entry;
                ip = host.ipv4;
              })
              alias
        )

        config.homelab.hosts
    );

  fileZone = pkgs.writeText "h.zone" ''
    $ORIGIN ${config.homelab.domain}.
    @       IN SOA ns nomail (
            1         ; Version number
            60        ; Zone refresh interval
            30        ; Zone update retry timeout
            180       ; Zone TTL
            3600)     ; Negative response TTL

    h. IN NS ns.${config.homelab.domain}.

    ns ${toString ttl} IN A ${config.homelab.currentHost.ipv4}

    ; hosts
    ${lib.concatMapStringsSep "\n" (host:
        "${host.name}.${config.homelab.domain}. ${toString ttl} IN A ${host.ip}")
      hostsIps}

    ; alias
    ${lib.concatMapStringsSep "\n" (host:
        "${host.name}.${config.homelab.domain}. ${toString ttl} IN A ${host.ip}")
      aliasIps}
  '';
in
lib.mkIf (roleEnabled)
{
  services.coredns.enable = true;

  networking.firewall.allowedTCPPorts = [ 53 9153 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.coredns.config =
    ''
      . {
          forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
          prometheus ${config.homelab.currentHost.ipv4}:9153
          cache
          log
        }

      ${config.homelab.domain} {
          file ${fileZone}
          prometheus ${config.homelab.currentHost.ipv4}:9153
          log
        }
    '';
}
