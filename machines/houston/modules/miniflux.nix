{
  config,
  clan-core,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  authDomain = "douane.${domain}";
  appDomain = "journaliste.${domain}";
  listenPort = 10002;
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

      cat > "$out/miniflux-env" << EOF
      OAUTH2_CLIENT_SECRET=$CLIENTSECRET
      ADMIN_USERNAME=admin
      ADMIN_PASSWORD=$ADMINPASSWORD
      EOF
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
        "https://journaliste.${config.networking.fqdn}/oauth2/oidc/callback"
      ];

      scopes = [
        "openid"
        "email"
        "profile"
        "groups"
      ];
    }
  ];

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;

    config = {
      LISTEN_ADDR = "127.0.0.1:${toString listenPort}";
      BASE_URL = "https://${appDomain}";
      HTTP_CLIENT_MAX_BODY_SIZE = "33554432";

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

      extraConfig = ''
        # Forward auth to Authelia
        auth_request /authelia;

        # Transmit headers for authentification
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $email $upstream_http_remote_email;

        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Email $email;

        # Error redirection
        error_page 401 =302 https://douane.${config.networking.fqdn}/?rd=$scheme://$http_host$request_uri;
      '';
    };

    locations."/authelia" = {
      proxyPass = "http://127.0.0.1:9091/api/verify";
      extraConfig = ''
        internal;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-Method $request_method;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Content-Length "";
        proxy_pass_request_body off;
      '';
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
