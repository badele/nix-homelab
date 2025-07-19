{
  self,
  config,
  ...
}:
let
  ttl = 300;
  fqdn = "ma-cabane.eu";
  houston_ip = "91.99.130.127";
in
{
  # resource.hetznerdns_zone.ma-cabane-eu = {
  #   name = fqdn;
  #   ttl = 3600;
  # };

  data.hetznerdns_zone.ma-cabane-eu = {
    name = fqdn;
  };

  output.ma-cabane-eu_zone_id = {
    value = config.data.hetznerdns_zone.ma-cabane-eu "id";
  };

  ############################################################################
  # Static DNS
  ############################################################################
  resource.hetznerdns_record =
    let
      createDnsRecord = record: {
        name = record.name;
        value = {
          zone_id = config.data.hetznerdns_zone.ma-cabane-eu "id";
          name = record.recordName;
          type = record.type;
          value = record.value;
          ttl = record.ttl;
        };
      };

      # Wildcard root entry added by machines/houston/terraform-configuration.nix
      dnsRecords = [
        # {
        #   name = "root_a";
        #   recordName = "@";
        #   type = "A";
        #   value = houston_ip;
        #   ttl = ttl;
        # }

        # {
        #   name = "home";
        #   recordName = "@";
        #   type = "A";
        #   value = houston_ip;
        #   ttl = ttl;
        # }
        # {
        #   name = "auth";
        #   recordName = "@";
        #   type = "A";
        #   value = houston_ip;
        #   ttl = ttl;
        # }
        # {
        #   name = "links";
        #   recordName = "@";
        #   type = "A";
        #   value = houston_ip;
        #   ttl = ttl;
        # }
        # {
        #   name = "rss";
        #   recordName = "@";
        #   type = "A";
        #   value = houston_ip;
        #   ttl = ttl;
        # }
      ];

    in
    builtins.listToAttrs (map createDnsRecord dnsRecords);
}
