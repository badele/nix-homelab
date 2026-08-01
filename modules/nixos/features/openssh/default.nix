{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  appName = "openssh";
  appDisplayName = "OpenSSH";
  appCategory = "Core Services";
  appIcon = "sh-openssh";
  appPlatform = "nixos";
  appDescription = "${pkgs.openssh.meta.description}";
  appUrl = pkgs.openssh.meta.homepage;
  appPinnedVersion = pkgs.openssh.version;

  cfg = config.homelab.features.${appName};
  primaryPort = head config.services.openssh.ports;
  listenAddresses = resolveListenInterfaceAddresses appName cfg.listenInterfaces;
  sshListenAddresses = flatten (
    map (
      address:
      map (port: {
        addr = address;
        port = port;
      }) config.services.openssh.ports
    ) listenAddresses
  );
  exposedURL = "ssh://${cfg.serviceDomain}:${toString primaryPort}";
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      serviceDomain = mkOption {
        type = str;
        default = "ssh.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
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
          serviceURL = exposedURL;
        };
      };
    }

    (mkIf cfg.enable {
      services.openssh = {
        enable = true;
        openFirewall = false;
        listenAddresses = sshListenAddresses;
      };

      networking.firewall.interfaces = mkIf cfg.openFirewall (
        lib.genAttrs cfg.listenInterfaces (_: {
          allowedTCPPorts = config.services.openssh.ports;
        })
      );
    })
  ];
}
