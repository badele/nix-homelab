{ lib, config, pkgs, ... }:
let
  roleName = "acme";
  roleEnabled = builtins.elem roleName config.homelab.currentHost.roles;
in
lib.mkIf (roleEnabled)
{
  # Configure sops secret 
  sops.secrets.gandi-apikey = { };

  # Wildcard certificate issued via DNS-01 challenge.
  security.acme = {
    acceptTerms = true;
    defaults.email = "brunoadele+acme@gmail.com";
    certs."${config.homelab.domain}" = {
      domain = "*.${config.homelab.domain}";
      extraDomainNames = [ config.homelab.domain ];
      dnsProvider = "gandiv5";
      group = "nginx";
      credentialsFile = config.sops.secrets.gandi-apikey.path;
      dnsPropagationCheck = true;
    };
  };
}
