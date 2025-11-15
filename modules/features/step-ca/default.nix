{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  ...
}:
with lib;
with types;
let
  appName = "step-ca";
  appCategory = "Core Services";
  appDisplayName = "Step CA";
  appPlatform = "nixos";
  appIcon = "step-ca";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appHealthUrl = "${serviceURL}/health";
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};
  secrets = config.clan.core.vars.generators;
  ip = config.homelab.host.address;

  # Get port from central registry
  listenHttpPort = config.homelab.portRegistry.${appName}.httpPort;

  # Service URL: use nginx domain if firewall is open, otherwise use direct IP:port
  serviceURL = "https://${cfg.serviceDomain}:${toString listenHttpPort}";

  yaml = pkgs.formats.json { };
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      serviceDomain = mkOption {
        type = str;
        default = "ca.${config.homelab.domain}";
        description = "${appName} service domain name / API REST (ACME)";
      };

      settings = mkOption {
        type = yaml.type;
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
          category = appCategory;
          displayName = appDisplayName;
          platform = appPlatform;
          icon = appIcon;
          description = appDescription;
          url = appUrl;
          pinnedVersion = appPinnedVersion;
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {
      homelab.features.${appName} = {
        homepage = {
          icon = appIcon;
          href = appHealthUrl;
          description = appDescription;
          siteMonitor = appHealthUrl;
        };

        gatus = mkIf cfg.enable {
          name = appDisplayName;
          url = appHealthUrl;
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY].status == ok"
            "[RESPONSE_TIME] < 50"
          ];
        };

      };

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

            owner = "step-ca";
            group = "step-ca";
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
        listenHttpPort
      ];

      # Trust the root CA system-wide
      security.pki.certificateFiles = [
        secrets.step-ca-root-ca.files."root-ca.crt".path
      ];

      # ACME configuration for automatic certs
      security.acme = {
        acceptTerms = true;
        defaults.server = "https://${cfg.serviceDomain}:${toString listenHttpPort}/acme/acme/directory";
        defaults.email = "admin@ma-cabane";
      };

      homelab.alias = [ "${cfg.serviceDomain}" ];

      # Add service management aliases
      programs.bash.shellAliases = mkServiceAliases appName // {
        # TODO: create script for best visibility
        "@service-${appName}-reset-all-acme-certs" =
          "systemctl stop 'acme-*' ; rm -rf /var/lib/acme/.lego/* ; rm -rf /var/lib/acme/* ; rm -rf /var/lib/acme/.lego ; systemctl start --all 'acme-order-renew-*'";
      };

      services.${appName} = {
        enable = true;
        port = listenHttpPort;
        address = ip;
        settings = cfg.settings;

        intermediatePasswordFile = secrets.step-ca-intermediate-ca.files."intermediate-password.txt".path;
      };

    })
  ];
}
