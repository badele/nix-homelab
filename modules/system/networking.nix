{ outputs, lib, config, ... }:
let
  domain = config.networking.domain;
in
{
  networking = {
    domain = "adele.lan";
    enableIPv6 = false;


    # add an entry to /etc/hosts for each host
    extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: host: ''${host.ipv4} ${lib.optionalString (host.alias != null) "${host.alias}"} ${name}'')
      config.networking.homelab.hosts);

    # For ZFS
    hostId = "9cd5e8c7";
  };
}
