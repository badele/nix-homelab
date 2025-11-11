{
  analytics = {
    check_for_plugin_updates = true;
    check_for_updates = false;
    feedback_links_enabled = false;
    reporting_enabled = false;
  };
  # "auth.anonymous" = {
  #   enable = true;
  #   enabled = true;
  #   hide_version = true;
  #   org_name = "ma cabane";
  #   org_role = "Viewer";
  # };
  # "auth.generic_oauth" = {
  #   allow_assign_grafana_admin = true;
  #   allow_sign_up = true;
  #   api_url = "https://douane.ma-cabane.eu/api/oidc/userinfo";
  #   auth_url = "https://douane.ma-cabane.eu/api/oidc/authorization";
  #   auto_login = false;
  #   client_id = "grafana";
  #   client_secret = "$__file{/run/secrets/vars/grafana/oauth2-client-secret}";
  #   email_attribute_path = "email";
  #   empty_scopes = false;
  #   enabled = true;
  #   groups_attribute_path = "groups";
  #   icon = "signin";
  #   login_attribute_path = "preferred_username";
  #   name = "Authelia";
  #   name_attribute_path = "name";
  #   role_attribute_path = "contains(groups, 'grafana-superadmins') && 'GrafanaAdmin' || contains(groups, 'grafana-admins') && 'Admin' || contains(groups, 'grafana-editors') && 'Editor' || contains(groups, 'grafana-viewers') && 'Viewer'";
  #   role_attribute_strict = true;
  #   scopes = [
  #     "openid"
  #     "profile"
  #     "email"
  #     "groups"
  #   ];
  #   skip_org_role_sync = false;
  #   token_url = "https://douane.ma-cabane.eu/api/oidc/token";
  #   use_pkce = true;
  # };
  # database = {
  #   ca_cert_path = null;
  #   cache_mode = "private";
  #   client_cert_path = null;
  #   client_key_path = null;
  #   conn_max_lifetime = 14400;
  #   host = "/run/postgresql";
  #   isolation_level = null;
  #   locking_attempt_timeout_sec = 0;
  #   log_queries = false;
  #   max_idle_conn = 2;
  #   max_open_conn = 0;
  #   name = "grafana";
  #   password = "";
  #   path = "/var/lib/grafana/data/grafana.db";
  #   query_retries = 0;
  #   server_cert_name = null;
  #   ssl_mode = "disable";
  #   transaction_retries = 5;
  #   type = "postgres";
  #   user = "grafana";
  #   wal = false;
  # };
  # paths = {
  #   plugins = "/var/lib/grafana/plugins";
  #   provisioning = «derivation /nix/store/5cjyf4szzcz2ng1a04crz8xxhp2v40l9-grafana-provisioning.drv»;
  # };
  # security = {
  #   admin_email = "admin@localhost";
  #   admin_password = "$__file{/run/secrets/vars/grafana/admin_password}";
  #   admin_user = "admin";
  #   allow_embedding = false;
  #   content_security_policy = false;
  #   content_security_policy_report_only = false;
  #   cookie_samesite = "lax";
  #   cookie_secure = true;
  #   csrf_additional_headers = [ ];
  #   csrf_trusted_origins = [ ];
  #   data_source_proxy_whitelist = [ ];
  #   disable_brute_force_login_protection = false;
  #   disable_gravatar = false;
  #   disable_initial_admin_creation = false;
  #   secret_key = "$__file{/run/secrets/vars/grafana/secret_key}";
  #   strict_transport_security = false;
  #   strict_transport_security_max_age_seconds = 86400;
  #   strict_transport_security_preload = false;
  #   strict_transport_security_subdomains = false;
  #   x_content_type_options = true;
  #   x_xss_protection = false;
  # };

  # server = {
  #   cdn_url = null;
  #   cert_file = null;
  #   cert_key = null;
  #   domain = "lampiotes.ma-cabane.eu";
  #   enable_gzip = false;
  #   enforce_domain = false;
  #   http_addr = "127.0.0.1";
  #   http_port = 10009;
  #   protocol = "http";
  #   read_timeout = "0";
  #   root_url = "https://lampiotes.ma-cabane.eu";
  #   router_logging = false;
  #   serve_from_sub_path = false;
  #   socket = "/run/grafana/grafana.sock";
  #   socket_gid = -1;
  #   socket_mode = "0660";
  #   static_root_path = "/nix/store/rgmdk0dydgqd4q0gf7xdh0zalgn86kjy-grafana-12.2.1/share/grafana/public";
  # };
  # smtp = {
  #   cert_file = null;
  #   ehlo_identity = null;
  #   enabled = false;
  #   from_address = "admin@grafana.localhost";
  #   from_name = "Grafana";
  #   host = "localhost:25";
  #   key_file = null;
  #   password = "";
  #   skip_verify = false;
  #   startTLS_policy = null;
  #   user = null;
  # };
  users = {
    allow_org_create = false;
    allow_sign_up = false;
    allow_signup = false;
    auto_assign_org = true;
    auto_assign_org_id = 1;
    auto_assign_org_role = "Viewer";
    default_language = "en-US";
    default_theme = "dark";
    hidden_users = "";
    home_page = "";
    login_hint = "email or username";
    password_hint = "password";
    user_invite_max_lifetime_duration = "24h";
    verify_email_enabled = false;
    viewers_can_edit = false;
  };
}
