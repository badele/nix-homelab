{ config, pkgs, ... }:
let
  domain = "auth.${config.networking.fqdn}";
  certs = config.security.acme.certs."${domain}";
in
{
  imports = [ ../../../modules/acme.nix ];

  clan.core.vars.generators.kanidm = {
    files.admin-password = {
      owner = config.systemd.services.kanidm.serviceConfig.User;
      group = config.systemd.services.kanidm.serviceConfig.Group;
    };
    files.idm-admin-password = {
      owner = config.systemd.services.kanidm.serviceConfig.User;
      group = config.systemd.services.kanidm.serviceConfig.Group;
    };

    runtimeInputs = [ pkgs.pwgen ];
    script = ''
      pwgen -s 48 1 > "$out"/admin-password
      pwgen -s 48 1 > "$out"/idm-admin-password
    '';
  };

  services.kanidm = {
    enableServer = true;

    package = pkgs.kanidmWithSecretProvisioning_1_6;
    serverSettings = {
      inherit domain;
      origin = "https://${domain}";
      tls_chain = "${certs.directory}/fullchain.pem";
      tls_key = "${certs.directory}/key.pem";

      online_backup = {
        path = "/var/backup/kanidm/";
        schedule = "0 23 * * *";
        versions = 7;
      };
    };
    provision = {
      enable = true;
      autoRemove = true;
      adminPasswordFile = config.clan.core.vars.generators.kanidm.files.admin-password.path;
      idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files.idm-admin-password.path;

      persons = {
        badele = {
          displayName = "Bruno Adelé";
          mailAddresses = [ "brunoadele@gmail.com" ];
          groups = [
            "miniflux.access"
          ];
        };
      };
    };

  };

  systemd.services.kanidm = {
    after = [ "acme-selfsigned-internal.${domain}.target" ];
    serviceConfig = {
      SupplementaryGroups = [ certs.group ];
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
