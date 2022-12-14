{ lib, config, ... }:
let
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
        config.homelab.hosts
    );
in
{
  networking = {
    domain = config.homelab.domain;
    enableIPv6 = false;

    # add an entry to /etc/hosts for each host
    extraHosts = ''
      # Hosts
        ${lib.concatStringsSep "\n"
          (lib.mapAttrsToList
            (hostname: hostinfo:
              ''${hostinfo.ipv4} ${hostname}.${config.homelab.domain} ${hostname}'')
            config.homelab.hosts)}
    '';

    # For ZFS
    hostId = "9cd5e8c7";
  };
}
