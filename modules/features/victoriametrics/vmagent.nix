{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkPodmanAliases,
  ...
}:
with lib;
with types;

let
  appName = "victoriametrics-agent";
  cfg = config.homelab.features.${appName};
  cfg_metrics = config.homelab.features.victoriametrics;
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {

      agentRewriteUrl = mkOption {
        type = str;
        default = "https://${cfg_metrics.serviceDomain}/api/v1/write";
        description = "victoriametrics URL for pushing metrics";
      };

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
          category = "System Health";
          displayName = "Victoriametrics Agent";
          description = "Simple, Reliable, Efficient Monitoring (Scraping Agent).";
          platform = "podman";
          icon = "victoriametrics";
          url = "https://victoriametrics.com";
          image = "victoriametrics/vmagent";
          version = "v1.129.1";
        };
      };
    }

    # Only apply when enabled
    (lib.mkIf cfg.enable {

      # Add Podman management aliases
      programs.bash.shellAliases = mkPodmanAliases appName;

      virtualisation.oci-containers.containers."${appName}" = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        cmd = [
          "-remoteWrite.url=${cfg.agentRewriteUrl}"
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
    })
  ];
}
