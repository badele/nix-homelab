{
  config,
  pkgs,
  ...
}:
{
  ############################################################################
  # Clan Credentials
  ############################################################################
  clan.core.vars.generators.influxdb = {
    files.admin_password = {
      owner = "influxdb2";
      group = "influxdb2";
      mode = "0400";
    };
    files.token_key = {
      owner = "influxdb2";
      group = "influxdb2";
      mode = "0400";
    };

    runtimeInputs = [
      pkgs.pwgen
    ];
    script = ''
      ADMINPASSWORD="$(pwgen -s 48 1)"
      TOKENKEY="$(pwgen -s 48 1)"

      echo "$ADMINPASSWORD" > "$out/admin_password"
      echo "$TOKENKEY" > "$out/token_key"
    '';
  };

  ############################################################################
  # Services
  ############################################################################
  services.influxdb2 = {
    enable = true;

    settings = {
      http-bind-address = "127.0.0.1:8086";

      log-level = "debug";
    };

    provision = {
      enable = true;

      initialSetup = {
        bucket = "default";
        organization = "homelab";
        username = "admin";
        passwordFile = config.clan.core.vars.generators."influxdb".files."admin_password".path;
        retention = 0;
        tokenFile = config.clan.core.vars.generators."influxdb".files."token_key".path;
      };
    };

  };
}
