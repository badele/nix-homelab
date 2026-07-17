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
  envGeneratorName = "acme-dns-01-${cfg.tokenScope}";
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

      tokenScope = mkOption {
        type = enum [
          "private"
          "public"
        ];
        default = "private";
        description = "Shared ACME credential scope used to select DNS API tokens.";
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
            serviceURL = "";
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
            group = config.services.caddy.group;
            environmentFile = config.clan.core.vars.generators.${envGeneratorName}.files.envfile.path;
            dnsPropagationCheck = true;
          };
        };

      })
    ];

}
