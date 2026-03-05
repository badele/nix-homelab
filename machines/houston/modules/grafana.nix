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
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_port = listenPort;
        http_addr = "127.0.0.1";
        domain = appDomain;
        root_url = "https://${appDomain}";
        protocol = "http";
      };
      "auth.anonymous".enable = true;

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
      users = {
        allow_signup = false;
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
        name = "Authelia";
        icon = "signin";
        client_id = "grafana";
        client_secret = "$__file{${
          config.clan.core.vars.generators."grafana".files."oauth2-client-secret".path
        }}";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        empty_scopes = false;
        auth_url = "https://douane.ma-cabane.eu/api/oidc/authorization";
        token_url = "https://douane.ma-cabane.eu/api/oidc/token";
        api_url = "https://douane.ma-cabane.eu/api/oidc/userinfo";
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        name_attribute_path = "name";
        email_attribute_path = "email";
        use_pkce = true;
        allow_assign_grafana_admin = true;
        role_attribute_path = builtins.concatStringsSep " || " [
          "contains(groups, 'grafana-superadmins') && 'GrafanaAdmin'"
          "contains(groups, 'grafana-admins') && 'Admin'"
          "contains(groups, 'grafana-editors') && 'Editor'"
          "contains(groups, 'grafana-viewers') && 'Viewer'"
        ];
        role_attribute_strict = true;
        skip_org_role_sync = false;
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
