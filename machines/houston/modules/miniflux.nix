{
  config,
  clan,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  authDomain = "auth.${domain}";
  appDomain = "rss.${domain}";
  listenPort = 10002;
in
{
  imports = [
    ../../../modules/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];

  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.miniflux = {
    files.oauth2-client-secret = {
      owner = "miniflux";
      group = "authelia-main";
      mode = "0440";
    };
    files.digest-client-secret = {
      owner = "miniflux";
      group = "authelia-main";
      mode = "0440";
    };
    files.miniflux-env = {
      owner = "miniflux";
      group = "authelia-main";
      mode = "0440";
    };

    runtimeInputs = [
      pkgs.pwgen
      pkgs.authelia
      pkgs.gnugrep
      pkgs.gawk
    ];
    script = ''
      CLIENTSECRET="$(pwgen -s 64 1)"
      DIGETSECRET="$(authelia crypto hash generate argon2 --password "$CLIENTSECRET" | grep Digest | awk '{ print $2 }')";
      ADMINPASSWORD="$(pwgen -s 48 1)"

      echo "$CLIENTSECRET" > "$out/oauth2-client-secret"
      echo "$DIGETSECRET" > "$out/digest-client-secret"
      printf "OAUTH2_CLIENT_SECRET=$CLIENTSECRET\nADMIN_USERNAME=admin\nADMIN_PASSWORD=$ADMINPASSWORD"  > "$out/miniflux-env"

    '';
  };

  ############################################################################
  # Service configuration
  ############################################################################
  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    createHome = true;
    homeMode = "0774";
  };

  users.groups.miniflux = { };

  services.authelia.instances.main.settings.identity_providers.oidc.clients = [
    {
      client_id = "miniflux";
      client_name = "Miniflux RSS Reader";

      # clan vars get houston miniflux/digest-client-secret
      client_secret = "$argon2id$v=19$m=65536,t=3,p=4$0N9qCsFAHvQpnAdLl+X8Dw$4Y2nNCjtK4BNs9zC3YmHFY6uNp80prHBctTWn2KE/u4";
      public = false;
      authorization_policy = "two_factor";
      redirect_uris = [
        "https://rss.${config.networking.fqdn}/oauth2/oidc/callback"
      ];
      scopes = [
        "openid"
        "email"
        "profile"
      ];
    }
  ];

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;

    config = {
      LISTEN_ADDR = "127.0.0.1:${toString listenPort}";
      BASE_URL = "https://${appDomain}";

      # https://www.authelia.com/integration/openid-connect/miniflux/
      OAUTH2_OIDC_PROVIDER_NAME = "Authelia";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE =
        config.clan.core.vars.generators."miniflux".files."digest-client-secret".path;
      OAUTH2_REDIRECT_URL = "https://${appDomain}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${authDomain}";
      OAUTH2_USER_CREATION = "1";

    };
    adminCredentialsFile = config.clan.core.vars.generators."miniflux".files."miniflux-env".path;
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
    miniflux = {
      service = "miniflux";
      restore = {
        stopOnRestore = [ "miniflux" ];
      };
    };
  };
}
