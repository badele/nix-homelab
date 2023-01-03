{ outputs, lib, config, ... }:
{
  networking = {
    domain = config.networking.homelab.domain;
    enableIPv6 = false;

    # add an entry to /etc/hosts for each host
    # extraHosts = lib.concatStringsSep "\n" (lib.mapAttrsToList
    #   (hostkey: hostinfo: ''${hostinfo.ipv4} ${lib.optionalString (hostinfo.alias != null) "${hostinfo.alias}"} ${hostkey}'')
    #   config.networking.homelab.hosts);

    # For ZFS
    hostId = "9cd5e8c7";
  };
}
