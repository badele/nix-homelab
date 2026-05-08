{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  subDomain = "lampiotes";
  appDomain = "${subDomain}.${domain}";
  listenPort = 10009;
in

{
  ############################################################################
  # Clan Credentials
  ############################################################################
  # Before insert the token, you need to create the user and the org in influxdb
  # grafana with ([buckets, orgs, takss] permission
  clan.core.vars.generators.grafana = {
    files.oauth2-client-secret = {
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };
    files.admin_password = {
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };
    files.secret_key = {
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };

    runtimeInputs = [
      pkgs.pwgen
      pkgs.gnugrep
      pkgs.gawk
    ];

    script = ''
      CLIENTSECRET="$(pwgen -s 48 1)"
      ADMINPASSWORD="$(pwgen -s 48 1)"
      SECRETKEY="$(pwgen -s 48 1)"

      echo "$CLIENTSECRET" > "$out/oauth2-client-secret"

      echo "$ADMINPASSWORD" > "$out/admin_password"
      echo "$SECRETKEY" > "$out/secret_key"
    '';
  };

  ############################################################################
  # Services
  ############################################################################
  services.prometheus.enable = true;
  hardware.mcelog.enable = true;
  services.sysstat.enable = true;

  services.postgresql = {
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "grafana"
    ];

    # Grafana connects via unix socket as linux user "grafana" to PG role "grafana"
    authentication = lib.mkBefore ''
      # TYPE    DATABASE        USER            ADDRESS                 METHOD
      # local = unix socket, host = TCP/IP
      # DATABASE = target database name (or "all")
      # USER = PostgreSQL role name (or "all")
      # ADDRESS = IP range (only for host type)
      # METHOD = auth method (trust=no password, peer=linux user must match PG role)

      # Grafana: peer auth on local socket
      local   grafana         grafana                                 peer
    '';
  };

  services.grafana = {
    enable = true;

    settings = {
      # log = {
      #   level = "debug";
      #   filters = "oauth.generic_oauth:debug";
      # };

      server = {
        http_port = listenPort;
        http_addr = "127.0.0.1";
        domain = appDomain;
        root_url = "https://${appDomain}";
        protocol = "http";
      };

      database = lib.mkDefault {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
        ssl_mode = "disable";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
      security = {
        cookie_secure = true;
        admin_password = "$__file{${
          config.clan.core.vars.generators."grafana".files."admin_password".path
        }}";
        secret_key = "$__file{${config.clan.core.vars.generators."grafana".files."secret_key".path}}";
      };

      # Create the user in Grafana when they first log in with OIDC, and assign them to the default organization
      users = {
        allow_signup = true;
      };

      "auth.anonymous" = {
        enabled = true;
        org_name = "ma cabane";
        org_role = "Viewer";
        hide_version = true;
      };

      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        auto_login = false;
        name = "Zitadel";
        icon = "signin";
        client_id = "371357670822707201";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];

        auth_url = "https://douane.ma-cabane.eu/oauth/v2/authorize";
        token_url = "https://douane.ma-cabane.eu/oauth/v2/token";
        api_url = "https://douane.ma-cabane.eu/oidc/v1/userinfo";

        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        email_attribute_path = "email";
        allow_assign_grafana_admin = true;

        use_pkce = true;
        groups_attribute_path = "groups";
        role_attribute_strict = true;
        role_attribute_path = builtins.concatStringsSep " || " [
          "contains(groups, 'grafana-superadmins') && 'GrafanaAdmin'"
          "contains(groups, 'grafana-admins') && 'Admin'"
          "contains(groups, 'grafana-editors') && 'Editor'"
          "contains(groups, 'grafana-viewers') && 'Viewer'"
        ];
      };
    };
  };

  ############################################################################
  # Reverse Proxy
  ############################################################################
  services.nginx.virtualHosts."${appDomain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
    extraConfig = "access_log /var/log/nginx/public.log vcombined;";
  };

  networking.firewall.allowedTCPPorts = [
    443
  ];

}
