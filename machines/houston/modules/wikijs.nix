{
  config,
  clan-core,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "notes.${domain}";
  listenPort = 10006;
in
{
  imports = [
    clan-core.clanModules.postgresql

    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];

  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.wiki-js = {
    files.oauth2-client-secret = {
      owner = "wiki-js";
      group = "authelia-main";
      mode = "0440";
    };
    files.digest-client-secret = {
      owner = "wiki-js";
      group = "authelia-main";
      mode = "0440";
    };
    # files.envfile = {
    #   owner = "wiki-js";
    #   group = "authelia-main";
    #   mode = "0440";
    # };
    #
    # runtimeInputs = [
    #   pkgs.pwgen
    #   pkgs.authelia
    #   pkgs.gnugrep
    #   pkgs.gawk
    # ];
    # script = ''
    #   CLIENTSECRET="$(pwgen -s 64 1)"
    #   DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";
    #   ADMINPASSWORD="$(pwgen -s 48 1)"
    #
    #   echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
    #   echo "$DIGETSECRET" > "$out/digest-client-secret"
    #   printf "OAUTH2_CLIENT_SECRET=$CLIENTSECRET\nADMIN_USERNAME=admin\nADMIN_PASSWORD=$ADMINPASSWORD"  > "$out/envfile"
    #
    # '';
  };

  ############################################################################
  # Service configuration
  ############################################################################
  users.users.wiki-js = {
    isSystemUser = true;
    group = "wiki-js";
    createHome = true;
    homeMode = "0774";
  };

  users.groups.wiki-js = { };

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "wiki-js";
      client_name = "Wikijs";

      # clan vars get houston wiki-js/digest-client-secret
      client_secret = "$argon2id$v=19$m=65536,t=3,p=4$RWh5hfYoUKlF8S2Rlqwv1Q$vv87++wXl6dFToApzthhiqcSk3AI33QzdzvQL4orrUo";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://notes.${config.networking.fqdn}/login/0c302403-1076-427a-88ff-ea23788f50de/callback"
      ];
      scopes = [
        "openid"
        "email"
        "profile"
      ];
      token_endpoint_auth_method = "client_secret_post";
    }
  ];

  services.postgresql = {
    ensureUsers = [
      {
        name = "wiki-js";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "wiki-js"
    ];
  };

  services.wiki-js = {
    enable = true;
    settings = {
      port = listenPort;

      db = {
        type = "postgres";
        host = "/run/postgresql";
        db = "wiki-js";
        user = "wiki-js";
      };
    };
    # createDatabaseLocally = true;

    # config = {
    #   LISTEN_ADDR = "127.0.0.1:${toString listenPort}";
    #   BASE_URL = "https://${appDomain}";
    #
    #   # https://www.authelia.com/integration/openid-connect/wiki-js/
    #   OAUTH2_OIDC_PROVIDER_NAME = "Authelia";
    #   OAUTH2_PROVIDER = "oidc";
    #   OAUTH2_CLIENT_ID = "wiki-js";
    #   OAUTH2_CLIENT_SECRET_FILE =
    #     config.clan.core.vars.generators."wiki-js".files."digest-client-secret".path;
    #   OAUTH2_REDIRECT_URL = "https://${appDomain}/oauth2/oidc/callback";
    #   OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${authDomain}";
    #   OAUTH2_USER_CREATION = "1";
    # };
    # oidcAuthentication = {
    #   authUrl = "https://auth.ma-cabane.eu/api/oidc/authorization";
    #   clientId = "wiki-js";
    #   clientSecretFile = config.clan.core.vars.generators."wiki-js".files."digest-client-secret".path;
    #
    #   displayName = "Authelia";
    #   tokenUrl = "https://auth.ma-cabane.eu/api/oidc/token";
    #   userinfoUrl = "https://auth.ma-cabane.eu/api/oidc/userinfo";
    # };
    #
    # publicUrl = "https://notes.${config.networking.fqdn}";
    # storage.storageType = "local";
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

  #############################################################################
  # Backup
  #############################################################################
  clan.postgresql.databases = {
    wiki-js = {
      service = "wiki-js";
      restore = {
        stopOnRestore = [ "wiki-js" ];
      };
    };
  };
}
