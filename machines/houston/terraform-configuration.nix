{
  config,
  lib,
  ...
}:
let
  tf_houston = config.resource.hcloud_server.houston;
in
{
  terraform.required_providers.local.source = "hashicorp/local";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";
  terraform.required_providers.hcloud.source = "hetznercloud/hcloud";

  #############################################################################
  # hetzner instance installation
  #############################################################################
  # https://www.hetzner.com/cloud/
  # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
  # https://docs.hetzner.com/cloud/general/locations/#what-locations-are-there
  resource.hcloud_server.houston = {
    name = "houston";
    server_type = "cx32";
    image = "debian-11";
    location = "nbg1";
    public_net = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
    backups = false;
    ssh_keys = [
      config.resource.hcloud_ssh_key.badele.name
    ];
  };

  ## Install the houston server with clan tool
  resource.null_resource.install-houston = {
    triggers = {
      instance_id = "\${hcloud_server.houston.id}";
    };

    # Use the SSH GPG key (YubiKey) to connect to the server
    provisioner.local-exec = {
      command = "clan machines install houston --update-hardware-config nixos-facter --target-host root@\${hcloud_server.houston.ipv4_address} --yes";
    };
  };

  #############################################################################
  # hetzner DNS records
  #############################################################################

  resource.hetznerdns_record.ma-cabane-eu_root_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "@";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_houston_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "houston";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_home_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "home";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_auth_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "auth";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_rss_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "rss";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_links_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "links";
    type = "A";
    value = tf_houston "ipv4_address";
  };

  resource.hetznerdns_record.ma-cabane-eu_stats_a = {
    zone_id = lib.tf.ref "module.dns.ma-cabane-eu_zone_id";
    name = "stats";
    type = "A";
    value = tf_houston "ipv4_address";
  };

}
