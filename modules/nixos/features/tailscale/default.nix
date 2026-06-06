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
  appName = "tailscale";
  appDisplayName = "Tailscale";
  appCategory = "Core Services";
  appIcon = "tailscale";
  appPlatform = "nixos";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;
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

        clan.core.vars.generators.prompt_auth_key = {
          prompts."auth_key" = {
            description = "Please insert the tailscale auth key machine";
            persist = true;
          };
        };

        clan.core.vars.generators.tailscale = {
          files.auth_key = { };

          dependencies = [
            "prompt_auth_key"
          ];
          script = ''
            cat $in/prompt_auth_key/auth_key > $out/auth_key
          '';
        };

        networking.firewall.trustedInterfaces = [ "tailscale0" ];

        services.tailscale = {
          enable = true;

          authKeyFile = config.clan.core.vars.generators.tailscale.files.auth_key.path;

          # useRoutingFeatures = "both";
          # extraUpFlags = [ "--accept-dns=false" ];
        };
      })
    ];
}
