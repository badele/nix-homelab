{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  ...
}:
with lib;
with types;

let
  appName = "acme";
  appDisplayName = "ACME";
  appCategory = "Core Services";
  appIcon = "sh-lets-encrypt";
  appPlatform = "nixos";
  appDescription = "${pkgs.lego.meta.description}";
  appUrl = pkgs.lego.meta.homepage;
  appPinnedVersion = pkgs.lego.version;

  cfg = config.homelab.features.${appName};
in
{
  # Hetzner
  # #######
  # To use Hetzner DNS provider, create a Hetzner API token with
  #

  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      email = mkOption {
        type = str;
        default = "firstname.lastname@mydomain.com";
        description = "Email used for ACME registration and recovery contact.";
      };

      dnsProvider = mkOption {
        type = str;
        default = "hetzner";
        description = "DNS provider for ACME DNS-01 challenges";
      };
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config =
    with lib;
    mkMerge [
      {
        homelab.features.${appName} = {
          appInfos = {
            category = appCategory;
            displayName = appDisplayName;
            icon = appIcon;
            platform = appPlatform;
            description = appDescription;
            url = appUrl;
            pinnedVersion = appPinnedVersion;
            serviceURL = serviceURL;
          };

        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {

        security.acme = {
          acceptTerms = true;
          defaults.email = cfg.email;
          certs."${config.homelab.domain}" = {
            domain = "*.${config.homelab.domain}";
            extraDomainNames = [ config.homelab.domain ];
            dnsProvider = cfg.dnsProvider;
            group = config.services.nginx.group;
            credentialsFile = config.clan.core.vars.generators.acme-dns-01.files.envfile.path;
            dnsPropagationCheck = true;
          };
        };

      })

      ########################################################################
      # Hetzner DNS provider specific configuration
      ########################################################################
      (mkIf (cfg.enable && cfg.dnsProvider == "hetzner") {

        # Begin hetzner acme config
        clan.core.vars.generators.prompt_acme_api_key = {
          prompts."acme_api_key" = {
            description = "Please insert ${cfg.dnsProvider} API TOKEN";
            persist = true;
          };
        };

        clan.core.vars.generators.acme-dns-01 = {
          files.envfile = {
            owner = config.services.nginx.user;
            group = config.services.nginx.group;
          };

          dependencies = [
            "prompt_acme_api_key"
          ];
          script = ''
            export APITOKEN=$(cat $in/prompt_acme_api_key/acme_api_key)
            echo "HETZNER_API_TOKEN=$APITOKEN" > $out/envfile
          '';
        };

      })
    ];

}
