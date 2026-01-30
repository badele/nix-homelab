{
  config,
  pkgs,
  lib,
  ...
}:

{
  variable.passphrase = { };

  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.hetznerdns = {
    source = "timohirt/hetznerdns";
    version = "~> 2.0";
  };
  terraform.required_providers.hcloud.source = "hetznercloud/hcloud";

  data.external.hetznerdns-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hetzner-dns-token)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  data.external.hcloud-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hetzner-homelab-token)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.hcloud.token = config.data.external.hcloud-token "result.secret";
  provider.hetznerdns.apitoken = config.data.external.hetznerdns-token "result.secret";
}
