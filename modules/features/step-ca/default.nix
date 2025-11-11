{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
}:
let
  appName = "step-ca";
  cfg = config.homelab.features.${appName};
  secrets = config.clan.core.vars.generators;
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;

  yaml = pkgs.formats.json { };
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} =
    with lib;
    with types;
    mkFeatureOptions {
      extraOptions = {
        serviceDomain = mkOption {
          type = str;
          default = "ca.${config.homelab.domain}";
          description = "${appName} service domain name / API REST (ACME)";
        };

        settings = mkOption {
          type = yaml.type;
          apply = yaml.generate "ca.json";
          default = import ./settings.nix {
            inherit
              config
              lib
              appName
              ;
          };
          description = ''
            Step CA configuration.
            See: https://smallstep.com/docs/step-ca/configuration
          '';
        };

        openFirewall = mkEnableOption "Open firewall ports (incoming)";

      };
    };

  ############################################################################
  # Configuration
  ############################################################################
  config = lib.mkMerge [
    # Always set appInfos, even when disabled
    {
      homelab.features.${appName} = {
        appInfos = {
          category = "Core Services";
          displayName = "Step CA";
          description = "Online Certificate Authority for secure automated certificate management";
          platform = "podman";
          icon = "step-ca";
          url = "https://smallstep.com/docs/step-ca";
          image = "smallstep/step-ca";
          version = "0.28.4";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      # Root CA
      clan.core.vars.generators = {
        step-ca-root-ca = {
          share = true;
          files."root-password.txt" = {
            secret = true;
            deploy = false;
          };
          files."root-ca.key" = {
            secret = true;
            deploy = false;
          };
          files."root-ca.crt" = {
            secret = false; # share to other machines
          };

          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            # Root CA password
            step crypto rand --format upper 32 > $out/root-password.txt

            # Root CA
            step certificate create "${config.homelab.domain} Root CA (nix-homelab)" \
              $out/root-ca.crt $out/root-ca.key \
              --profile root-ca \
              --password-file $out/root-password.txt \
              --not-after 87600h
          '';
        };

        # Intermediate CA
        step-ca-intermediate-ca = {
          files."intermediate-password.txt" = {
            secret = true;
            deploy = true; # Needed for step-ca
          };
          files."intermediate-ca.key" = {
            secret = true;
            deploy = true; # Needed for step-ca
          };
          files."intermediate-ca.crt" = {
            secret = false;
          };

          dependencies = [ "step-ca-root-ca" ];

          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            # Intermediate password
            step crypto rand --format upper 32 > $out/intermediate-password.txt

            # Intermediate keypair
            step crypto keypair \
              $out/intermediate.pub \
              $out/intermediate-ca.key \
              --password-file $out/intermediate-password.txt

            # Intermedia CA signed by root
            step certificate create "Intermediate ${config.homelab.domain} CA (nix-homelab)" \
              $out/intermediate-ca.crt $out/intermediate-ca.key \
              --profile intermediate-ca \
              --ca $in/step-ca-root-ca/root-ca.crt \
              --ca-key $in/step-ca-root-ca/root-ca.key \
              --password-file $out/intermediate-password.txt \
              --ca-password-file $in/step-ca-root-ca/root-password.txt \
              --not-after 8760h \
              --force
          '';
        };
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
        listenPort
      ];

      # Trust the root CA system-wide
      security.pki.certificateFiles = [
        secrets.step-ca-root-ca.files."root-ca.crt".path
      ];

      # ACME configuration for automatic certs
      security.acme = {
        acceptTerms = true;
        defaults.server = "https://${cfg.serviceDomain}:${toString listenPort}/acme/acme/directory";
        defaults.email = "admin@ma-cabane";
      };

      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add Podman management aliases
      programs.bash.shellAliases = mkPodmanAliases appName // {
        # TODO: create script for best visibility
        "@service-${appName}-reset-all-acme-certs" =
          "systemctl stop 'acme-*' ; rm -rf /var/lib/acme/.lego/* ; rm -rf /var/lib/acme/* ; rm -rf /var/lib/acme/.lego ; systemctl start --all 'acme-order-renew-*'";
      };

      virtualisation.oci-containers.containers.${appName} = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        ports = [
          "${ip}:${toString listenPort}:9000"
        ];

        volumes = [
          "${cfg.settings}:/home/step/config/ca.json:ro"
          "${secrets.step-ca-root-ca.files."root-ca.crt".path}:/home/step/certs/root_ca.crt:ro"
          "${
            secrets.step-ca-intermediate-ca.files."intermediate-ca.key".path
          }:/home/step/secrets/intermediate_ca_key:U,ro"
          "${
            secrets.step-ca-intermediate-ca.files."intermediate-ca.crt".path
          }:/home/step/certs/intermediate_ca.crt:ro"
          "${
            secrets.step-ca-intermediate-ca.files."intermediate-password.txt".path
          }:/home/step/secrets/password:U,ro"

        ];

        extraOptions = [
          "--cap-drop=ALL"

          # for nginx
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
          "--cap-add=NET_BIND_SERVICE"
          "--subuidname=root"
          "--subgidname=root"
        ];

      };
      # // cfg.containerInfos;
    })
  ];
}
