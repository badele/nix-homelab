{
  config,
  pkgs,
  ...
}:
let
  appDomain = "auth.${config.networking.fqdn}";
  certs = config.security.acme.certs."${appDomain}";

  secrets_permission = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
  };
in
{
  imports = [ ../../../modules/system/acme.nix ];

  clan.core.vars.generators.gmail-application-password = {
    prompts."token" = {
      description = "Please insert your GMail application password";
      persist = true;
    };
  };

  # Le generer qu'une seule fois, sinon, les données sont corompues utilisateurs
  clan.core.vars.generators.authelia-encryption-key = {
    files.storage-encryption-key = {
    };
    runtimeInputs = [ pkgs.pwgen ];
    script = ''
      pwgen -s 64 1 > "$out"/storage-encryption-key
    '';
  };

  clan.core.vars.generators.authelia = {
    files.gmail-application-password = secrets_permission;
    files.jwt-secret = secrets_permission;
    files.session-secret = secrets_permission;
    files.storage-encryption-key = secrets_permission;
    files.jwks-private-key = secrets_permission;
    files.jwks-certificate = secrets_permission;
    files.hmac-secret = secrets_permission;

    dependencies = [
      "gmail-application-password"
      "authelia-encryption-key"
    ];
    runtimeInputs = [
      pkgs.pwgen
      pkgs.authelia
      pkgs.openssl
    ];
    script = ''
      pwgen -s 64 1 > "$out"/jwt-secret
      pwgen -s 64 1 > "$out"/session-secret
      pwgen -s 64 1 > "$out"/hmac-secret
      authelia crypto certificate rsa generate \
        --common-name "auth.${config.networking.fqdn}" \
        --bits 2048 \
        --file.private-key jwks-private-key \
        --file.certificate jwks-certificate \
        --directory "$out"

      # openssl rsa -in "$out"/jwks-private-key -outform DER | base64 -w 0 > "$out"/jwks-private-key-base64
      # openssl x509 -in "$out"/jwks-certificate -outform DER | base64 -w 0 > "$out"/jwks-certificate-base64

      cat $in/authelia-encryption-key/storage-encryption-key > "$out"/storage-encryption-key
      cat $in/gmail-application-password/token > $out/gmail-application-password
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/authelia-main 0750 authelia-main authelia-main -"
  ];

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.clan.core.vars.generators.authelia.files.jwt-secret.path;
      sessionSecretFile = config.clan.core.vars.generators.authelia.files.session-secret.path;
      storageEncryptionKeyFile =
        config.clan.core.vars.generators.authelia.files.storage-encryption-key.path;
      oidcIssuerPrivateKeyFile = config.clan.core.vars.generators.authelia.files.jwks-private-key.path;
      oidcHmacSecretFile = config.clan.core.vars.generators.authelia.files.hmac-secret.path;
    };

    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
        config.clan.core.vars.generators.authelia.files.gmail-application-password.path;
      # AUTHELIA_JWT_SECRET_FILE = config.clan.core.vars.generators.authelia.files.jwt-secret.path;
      # AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE =
      #   config.clan.core.vars.generators.authelia.files.hmac-secret.path;
    };

    settings = {
      theme = "dark";
      default_redirection_url = "https://${config.networking.fqdn}";

      server = {
        address = "tcp://127.0.0.1:9091";
        asset_path = "";
        headers = {
          csp_template = "";
        };
      };

      log = {
        level = "info";
        format = "text";
      };

      webauthn = {
        disable = false;
        display_name = "Ma Cabane";
      };

      totp = {
        disable = false;
        issuer = "ma-cabane.eu";
        algorithm = "sha1";
        digits = 6;
        period = 30;
        skew = 1;
      };

      authentication_backend = {
        refresh_interval = "1m";
        file = {
          path = "/var/lib/authelia-main/users_database.yml";
          password = {
            algorithm = "argon2";
            argon2 = {
              variant = "argon2id";
              iterations = 3;
              memory = 65536;
              parallelism = 4;
              key_length = 32;
              salt_length = 16;
            };
          };
        };
      };

      session = {
        name = "authelia_session";
        domain = config.networking.fqdn;
        expiration = "1h";
        inactivity = "5m";
        remember_me = "1M";
      };

      regulation = {
        max_retries = 3;
        find_time = "2m";
        ban_time = "5m";
      };

      storage = {
        local = {
          path = "/var/lib/authelia-main/db.sqlite3";
        };
      };

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submission://smtp.gmail.com:587";
          username = "brunoadele@gmail.com";
          sender = "admin@${config.networking.fqdn}";
        };
      };

      # identity_providers.oidc = {
      #   hmac_secret = ''{{ env "TOTO" }}'';
      #   jwks = [
      #     {
      #       key_id = "authelia";
      #       algorithm = "RS256";
      #       use = "sig";
      #       key = ''{{- fileContent "${config.clan.core.vars.generators.authelia.files.jwks-private-key.path}" }}'';
      #       certificate_chain = ''{{- fileContent "${config.clan.core.vars.generators.authelia.files.jwks-certificate.path}"}}'';
      #     }
      #   ];
      # };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "auth.${config.networking.fqdn}";
            policy = "bypass";
          }

          # Allow all domain for admins
          {
            domain = "*.${config.networking.fqdn}";
            policy = "one_factor";
            subject = "group:admins";
          }

          ####################################################################
          # Apps for public group user
          ####################################################################
          {
            domain = "rss.${config.networking.fqdn}";
            policy = "one_factor";
            subject = [
              "group:public.access"
            ];
          }
          {
            domain = "links.${config.networking.fqdn}";
            policy = "one_factor";
            subject = [
              "group:public.access"
            ];
          }

          # Fallback pour autres services
          {
            domain = "*.${config.networking.fqdn}";
            policy = "deny";
          }
        ];
      };
    };
  };

  systemd.services.authelia-main = {
    after = [ "acme-selfsigned-internal.${appDomain}.target" ];
    serviceConfig = {
      SupplementaryGroups = [ certs.group ];
    };

  };

  services.nginx.virtualHosts.${appDomain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Upgrade $http_upgrade;
        proxy_cache_bypass $http_upgrade;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    443
  ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "authelia-create-user" ''
      #!/bin/bash
      set -euo pipefail

      if [ $# -ne 3 ]; then
          echo "Usage: $0 <username> <email> <displayname>"
          exit 1
      fi

      USERNAME=$1
      EMAIL=$2
      DISPLAYNAME=$3

      # Hash password with argon2 algorithm
      AUTHELIA=${pkgs.authelia}/bin/authelia
      HASHED_PASSWORD=$($AUTHELIA crypto hash generate argon2 --random | grep Digest | awk '{ print $2 }')

      USERFILE="/var/lib/authelia-main/users_database.yml"
      if grep -Pzo "users:\n  authelia:" $USERFILE > /dev/null; then
          cp $USERFILE $USERFILE.deleted
          echo "users:" > $USERFILE
      fi

      # Add user
      cat >> $USERFILE << EOF
        $USERNAME:
          displayname: "$DISPLAYNAME"
          password: "$HASHED_PASSWORD"
          email: "$EMAIL"
          groups:
            - public.access
      EOF

      echo "L'utilisateur devra utiliser la fonction 'Mot de passe oublié' pour le changer"

      # sudo systemctl restart authelia-main
    '')
  ];
}
