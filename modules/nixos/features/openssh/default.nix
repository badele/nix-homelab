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
  requiredListenAddresses = escapeShellArgs listenAddresses;
  waitForListenAddresses = pkgs.writeShellScript "wait-for-openssh-listen-addresses" ''
    timeout=120

    while [ "$timeout" -gt 0 ]; do
      missing=0

      for address in ${requiredListenAddresses}; do
        if ! ${pkgs.iproute2}/bin/ip -o -4 addr show | ${pkgs.gnugrep}/bin/grep -Fq " inet ''${address}/"; then
          echo "Waiting for OpenSSH listen address ''${address}"
          missing=1
        fi
      done

      if [ "$missing" -eq 0 ]; then
        exit 0
      fi

      timeout=$((timeout - 1))
      sleep 1
    done

    echo "Timed out waiting for OpenSSH listen addresses: ${requiredListenAddresses}" >&2
    exit 1
  '';
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

      systemd.services.sshd = mkIf (cfg.listenInterfaces != [ ]) {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          ExecStartPre = [ waitForListenAddresses ];
          RestartSec = "10s";
        };
      };

      networking.firewall.interfaces = mkIf cfg.openFirewall (
        lib.genAttrs cfg.listenInterfaces (_: {
          allowedTCPPorts = config.services.openssh.ports;
        })
      );
    })
  ];
}
