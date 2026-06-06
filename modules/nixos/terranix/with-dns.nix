{ config' }:
{
  pkgs,
  lib,
  ...
}:
{
  module.dns = {
    source = toString (
      pkgs.linkFarm "dns-module" [
        {
          name = "config.tf.json";
          path = config'.terranix.terranixConfigurations.dns.result.terraformConfiguration;
        }
      ]
    );
    passphrase = lib.tf.ref "var.passphrase";
  };
}
