{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
}:
let
  appName = "homelab-summary";
  cfg = config.homelab.features.${appName};
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} =
    with lib;
    with types;
    mkFeatureOptions {
      extraOptions = { };
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
          displayName = "Nix homelab summary";
          description = "Generate a static HTML summary of your Nix homelab instance";
          platform = "nixos";
          icon = "";
          url = "https://github.com/badele/nix-homelab";
          image = "";
          version = "";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable (
      let

        # Get all enabled features
        enabledFeatures = lib.filterAttrs (name: feature: feature.enable or false) config.homelab.features;

        # Transform to list of features with appInfos
        featuresList = lib.mapAttrsToList (name: feature: {
          name = name;
          inherit (feature.appInfos)
            category
            displayName
            description
            platform
            icon
            url
            image
            version
            ;
          enabled = feature.enable;
          httpPort = feature.httpPort or null;
          reverseProxy = feature.reverseProxy or false;
        }) enabledFeatures;

        # Group features by category
        groupedFeatures = lib.groupBy (service: service.category) featuresList;

        # Generate markdown content
        mkMarkdownTable =
          features:
          ''
            | Icon  | Service | Platform | Version | Description |
            |:-:|---------|:--------:|:-------:|-------------|
          ''
          + lib.concatMapStringsSep "\n" (
            service:
            let
              icon =
                if service.icon != null && service.icon != "" then
                  "<img src='https://cdn.jsdelivr.net/gh/selfhst/icons/png/${service.icon}.png' alt='${description}' width='48' height='48'>"
                else
                  "-";

              name =
                if service.url != null && service.url != "" then
                  "[${service.displayName}](${service.url})"
                else
                  service.displayName;
              version = if service.version != null && service.version != "" then service.version else "-";
              platform = service.platform;
              description = service.description;
            in
            "|${icon} | ${name} | ${platform} | ${version} | ${description} |"
          ) features;

        mkMarkdownContent = ''
          # ${config.networking.hostName}

          **Domain:** ${config.homelab.domain}
          **Total Features:** ${toString (builtins.length featuresList)}

        ''
        + lib.concatStringsSep "\n\n" (
          lib.mapAttrsToList (category: features: ''
            ## ${if category != "" then category else "Other"}

            ${mkMarkdownTable features}
          '') groupedFeatures
        );
      in
      {
        # Generate features summary JSON
        environment.etc."nix-homelab/features.json" = {
          text = builtins.toJSON {
            hostname = config.networking.hostName;
            domain = config.homelab.domain;
            features = featuresList;
          };
        };

        # Generate features summary Markdown
        environment.etc."nix-homelab/features.md" = {
          text = mkMarkdownContent;
        };
      }
    ))
  ];
}
