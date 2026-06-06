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
  appName = "caddy";
  appDisplayName = "Caddy";
  appCategory = "Core Services";
  appIcon = "sh-caddy";
  appPlatform = "nixos";
  appDescription = "${pkgs.caddy.meta.description}";
  appUrl = pkgs.caddy.meta.homepage;
  appPinnedVersion = pkgs.caddy.version;

  cfg = config.homelab.features.${appName};
  acmeCfg = config.homelab.features.acme;

  useHetznerDns = (cfg.enable || acmeCfg.enable) && cfg.dnsProvider == "hetzner";
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      email = mkOption {
        type = str;
        default = config.homelab.domainEmailAdmin;
        description = "Email used for Caddy ACME registration and recovery contact.";
      };

      dnsProvider = mkOption {
        type = str;
        default = acmeCfg.dnsProvider;
        description = "DNS provider for Caddy ACME DNS-01 challenges.";
      };

      propagationDelay = mkOption {
        type = str;
        default = "60s";
        description = "Delay before Caddy checks DNS challenge propagation.";
      };

      propagationTimeout = mkOption {
        type = str;
        default = "10m";
        description = "Maximum time Caddy waits for DNS challenge propagation.";
      };

      resolvers = mkOption {
        type = listOf str;
        default = [
          "213.133.100.102"
          "213.239.204.242"
          "193.47.99.4"
        ];
        description = "DNS resolvers used by Caddy to check DNS challenge propagation.";
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

      (mkIf useHetznerDns {
        clan.core.vars.generators.prompt_acme_api_key = {
          prompts."acme_api_key" = {
            description = "Please insert ${cfg.dnsProvider} API TOKEN";
            persist = true;
          };
        };

        clan.core.vars.generators.acme-dns-01 = {
          files.envfile = {
            owner = config.services.caddy.user;
            group = config.services.caddy.group;
          };

          dependencies = [
            "prompt_acme_api_key"
          ];
          script = ''
            APITOKEN=$(cat $in/prompt_acme_api_key/acme_api_key)
            echo "HETZNER_API_TOKEN=$APITOKEN" > $out/envfile
          '';
        };
      })

      (mkIf cfg.enable {
        services.caddy = {
          enable = true;
          email = cfg.email;
        }
        // optionalAttrs (cfg.dnsProvider == "hetzner") {
          environmentFile = config.clan.core.vars.generators.acme-dns-01.files.envfile.path;
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/hetzner/v2@v2.0.0" ];
            hash = "sha256-pQJ4X7o8Z2Ra2OteMrzP7guWcxBe4zfn8jFwIAdQ+Ow=";
          };
          globalConfig = ''
            cert_issuer acme {
              dns hetzner {$HETZNER_API_TOKEN}
              propagation_delay ${cfg.propagationDelay}
              propagation_timeout ${cfg.propagationTimeout}
              resolvers ${concatStringsSep " " cfg.resolvers}
            }
            auto_https disable_redirects
          '';
        };
      })
    ];
}
