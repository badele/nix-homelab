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

  data.hetznerdns_zone.adele-im = {
    name = "adele.im";
  };

  output.ma-cabane-eu_zone_id = {
    value = config.data.hetznerdns_zone.ma-cabane-eu "id";
  };

  ############################################################################
  # ma-cabane.eu Static DNS
  ############################################################################
  resource.hetznerdns_record =
    let
      createAdeleImDnsRecord = record: {
        name = record.name;
        value = {
          zone_id = config.data.hetznerdns_zone.adele-im "id";
          name = record.recordName;
          type = record.type;
          value = record.value;
          ttl = record.ttl;
        };
      };

      # Wildcard root entry added by machines/houston/terraform-configuration.nix
      maCavaneDnsRecords = [
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
      adeleImDnsRecords = [
        # Root A record
        {
          name = "root_a";
          recordName = "@";
          type = "A";
          value = "185.49.20.101";
          ttl = ttl;
        }

        # MX records for email
        {
          name = "mx_10";
          recordName = "@";
          type = "MX";
          value = "10 mx10.yulpa.io.";
          ttl = ttl;
        }
        {
          name = "mx_20";
          recordName = "@";
          type = "MX";
          value = "20 mx20.yulpa.io.";
          ttl = ttl;
        }
        {
          name = "mx_30";
          recordName = "@";
          type = "MX";
          value = "30 mx30.yulpa.io.";
          ttl = ttl;
        }

        # TXT records
        {
          name = "keybase_verification";
          recordName = "@";
          type = "TXT";
          value = "keybase-site-verification=PKiz-on1oe_-KOP4RQiRSoJFJAZxrfo9NIu_g6F9nXk";
          ttl = ttl;
        }

        # Google verification
        {
          name = "google_verification";
          recordName = "GHKLE4XGUSVG";
          type = "CNAME";
          value = "gv-ZGAKN6F7RKAKWVG25QPABOFHX6O6JIN7I64LYFW72CLRE4AWKGNQ.domainverify.googlehosted.com.";
          ttl = ttl;
        }

        # Personal CNAMEs
        {
          name = "bruno";
          recordName = "bruno";
          type = "CNAME";
          value = "@";
          ttl = ttl;
        }
        {
          name = "lou";
          recordName = "lou";
          type = "CNAME";
          value = "@";
          ttl = ttl;
        }
        {
          name = "lucas";
          recordName = "lucas";
          type = "CNAME";
          value = "@";
          ttl = ttl;
        }
        {
          name = "stephanie";
          recordName = "stephanie";
          type = "CNAME";
          value = "@";
          ttl = ttl;
        }
        {
          name = "wiki_serialkiller";
          recordName = "wiki.serialkiller";
          type = "CNAME";
          value = "@";
          ttl = ttl;
        }

        # DNS tools - Private IP classes
        {
          name = "class_a_priv_dns_tool_a";
          recordName = "class-a.priv.dns.tool";
          type = "A";
          value = "10.10.10.10";
          ttl = ttl;
        }
        {
          name = "class_a_priv_dns_tool_aaaa";
          recordName = "class-a.priv.dns.tool";
          type = "AAAA";
          value = "fd00:aaaa:aaaa::";
          ttl = ttl;
        }
        {
          name = "class_b_priv_dns_tool_a";
          recordName = "class-b.priv.dns.tool";
          type = "A";
          value = "172.16.16.16";
          ttl = ttl;
        }
        {
          name = "class_b_priv_dns_tool_aaaa";
          recordName = "class-b.priv.dns.tool";
          type = "AAAA";
          value = "fd00:bbbb:bbbb::";
          ttl = ttl;
        }
        {
          name = "class_c_priv_dns_tool_a";
          recordName = "class-c.priv.dns.tool";
          type = "A";
          value = "192.168.168.168";
          ttl = ttl;
        }
        {
          name = "class_c_priv_dns_tool_aaaa";
          recordName = "class-c.priv.dns.tool";
          type = "AAAA";
          value = "fd00:cccc:cccc::";
          ttl = ttl;
        }

        # Public DNS tool
        {
          name = "public_dns_tool_a";
          recordName = "public.dns.tool";
          type = "A";
          value = "8.8.8.8";
          ttl = ttl;
        }
        {
          name = "public_dns_tool_aaaa";
          recordName = "public.dns.tool";
          type = "AAAA";
          value = "::ffff:8.8.8.8";
          ttl = ttl;
        }

        # Zero DNS tool
        {
          name = "zero_priv_dns_tool";
          recordName = "zero.priv.dns.tool";
          type = "A";
          value = "0.0.0.0";
          ttl = ttl;
        }

        # Services
        {
          name = "domotique";
          recordName = "domotique";
          type = "A";
          value = "212.83.166.46";
          ttl = ttl;
        }
        {
          name = "home";
          recordName = "home";
          type = "A";
          value = "81.64.117.68";
          ttl = ttl;
        }
        {
          name = "traefik";
          recordName = "traefik";
          type = "A";
          value = "81.64.117.68";
          ttl = ttl;
        }
        {
          name = "adguard";
          recordName = "adguard";
          type = "A";
          value = "81.64.117.68";
          ttl = ttl;
        }
        {
          name = "note";
          recordName = "note";
          type = "A";
          value = "81.64.117.68";
          ttl = ttl;
        }
        {
          name = "rss";
          recordName = "rss";
          type = "A";
          value = "81.64.117.68";
          ttl = ttl;
        }
      ];
    in
    builtins.listToAttrs (map createAdeleImDnsRecord adeleImDnsRecords);
}
