{
  config,
  clan-core,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "codes.${domain}";
  listenPort = 10007;
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];

  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.wastebin = {
    files.envfile = { };
    runtimeInputs = [ pkgs.pwgen ];
    script = ''
      echo "WASTEBIN_PASSWORD_SALT=$(pwgen -s 64 1)" >> $out/envfile
      echo "WASTEBIN_SIGNING_KEY=$(pwgen -s 64 1)" >> $out/envfile
    '';
  };

  services.wastebin = {
    enable = true;

    secretFile = config.clan.core.vars.generators."wastebin".files."envfile".path;

    settings = {
      WASTEBIN_ADDRESS_PORT = "127.0.0.1:${toString listenPort}";
      WASTEBIN_TITLE = "codes";
      WASTEBIN_BASE_URL = "https://codes.ma-cabane.eu";
    };
  };

  services.nginx.virtualHosts."${appDomain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
    extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
  };
}
