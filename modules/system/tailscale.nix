{
  config,
  ...
}:
{
  clan.core.vars.generators.prompt_auth_key = {
    prompts."auth_key" = {
      description = "Please insert the tailscale auth key machine";
      persist = true;
    };
  };

  clan.core.vars.generators.tailscale = {
    files.auth_key = { };

    dependencies = [
      "prompt_auth_key"
    ];
    script = ''
      cat $in/prompt_auth_key/auth_key > $out/auth_key
    '';
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.tailscale = {
    enable = true;

    authKeyFile = config.clan.core.vars.generators.tailscale.files.auth_key.path;

    # useRoutingFeatures = "both";
    # extraUpFlags = [ "--accept-dns=false" ];
  };
}
