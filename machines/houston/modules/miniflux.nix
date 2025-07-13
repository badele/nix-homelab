{
  config,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  authdomain = "auth.${domain}";
  appdomain = "rss.${domain}";
  listenPort = 10001;

in
{
  imports = [ ../../../modules/acme.nix ];

  clan.core.vars.generators.miniflux = {
    files.oauth2-client-secret = {
      owner = "miniflux";
      group = "kanidm";
      mode = "0440";
    };
    files.admin-credentials = { };

    runtimeInputs = [ pkgs.pwgen ];
    script = ''
      printf "OAUTH2_CLIENT_SECRET='%s'" "$(pwgen -s 48 1)" > "$out/oauth2-client-secret"
      printf "ADMIN_USERNAME=admin\nADMIN_PASSWORD='%s'" "$(pwgen -s 48 1)" > "$out/admin-credentials"
    '';
  };

  services.kanidm.provision.groups."miniflux.access" = { };

  services.kanidm.provision.systems.oauth2.miniflux = {
    displayName = "Miniflux";
    originUrl = "https://${appdomain}/oauth2/oidc/callback";
    originLanding = "https://${appdomain}";
    allowInsecureClientDisablePkce = true;

    basicSecretFile = config.clan.core.vars.generators."miniflux".files."oauth2-client-secret".path;
    scopeMaps."miniflux.access" = [
      "openid"
      "profile"
      "email"
    ];
  };

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;

    config = {
      LISTEN_ADDR = "127.0.0.1:${toString listenPort}";
      BASE_URL = "https://${appdomain}";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE =
        config.clan.core.vars.generators."miniflux".files."oauth2-client-secret".path;
      OAUTH2_REDIRECT_URL = "https://${appdomain}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${authdomain}/oauth2/openid/miniflux";
      OAUTH2_USER_CREATION = "1";

    };
    adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."admin-credentials".path;
  };

  services.nginx.virtualHosts."${appdomain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
