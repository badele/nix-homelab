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
  # appName = "lldap";
  appName = "podman-lldap";
  cfg = config.homelab.features.${appName};
  ip = config.homelab.host.address;

  # Get port from central registry
  listenPort = config.homelab.portRegistry.${appName}.httpPort;
  appPath = "${config.homelab.podmanBaseStorage}/${appName}";

  containerUid = 1000;
  containerGid = 1000;

  hostUid = (builtins.elemAt config.users.users.root.subUidRanges 0).startUid + containerUid;
  hostGid = (builtins.elemAt config.users.users.root.subGidRanges 0).startGid + containerGid;
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      ldapDomain = mkOption {
        type = str;
        default = "dc=homelab,dc=lan";
        description = "Base DN for the LDAP directory";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";

    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
    # Always set appInfos, even when disabled
    {
      homelab.features.${appName} = {
        appInfos = {
          category = "Essentials";
          displayName = "Sample Podman application";
          description = "Sample podman application with hardening options.";
          platform = "podman";
          icon = "podman";
          url = "https://github.com/badele/nix-homelab";
          image = "lldap/lldap";
          pinnedVersion = "2025-09-28-alpine";
        };
      };
    }

    # Only apply when enabled
    (mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        3890
        17170
      ];

      clan.core.vars.generators.lldap = {
        files.jwt-secret = { };
        files.password = { };
        files.envfile = { };

        runtimeInputs = [
          pkgs.pwgen
        ];

        script = ''
          pwgen -s 32 1 > "$out/jwt-secret"
          pwgen -s 16 1 > "$out/password"

          KEYSEED="$(pwgen -s 32 1)"
          cat > "$out/envfile" << EOF
          LLDAP_KEY_SEED=$KEYSEED
          EOF
        '';
      };

      systemd.tmpfiles.rules = [
        # Application data
        "d ${appPath} 0750 root root -"
        "d ${appPath}/data 0750 root root -"

        # Backup directory
        "d /var/backup/lldap 0750 root root -"
      ];

      # Update secrets permissions before starting the container
      systemd.services."podman-${appName}" = {
        preStart = mkAfter ''
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."jwt-secret".path
          } 
          chown ${toString hostUid}:${toString hostGid} ${
            config.clan.core.vars.generators.${appName}.files."password".path
          }
        '';
      };

      virtualisation.oci-containers.containers.${appName} = {
        image = "${cfg.appInfos.image}:${cfg.appInfos.version}";

        ports = [
          "${ip}:3890:3890"
          "127.0.0.1:${toString listenPort}:17170"
        ];

        volumes = [
          "${appPath}/data:/data"
          "${config.clan.core.vars.generators.${appName}.files."jwt-secret".path}:/run/secrets/jwt-secret:ro"
          "${config.clan.core.vars.generators.${appName}.files."password".path}:/run/secrets/password:ro"
        ];

        environmentFiles = [
          config.clan.core.vars.generators.${appName}.files."envfile".path
        ];

        environment = {
          LLDAP_LDAP_BASE_DN = cfg.ldapDomain;
          LLDAP_JWT_SECRET_FILE = "/run/secrets/jwt-secret";
          LLDAP_LDAP_USER_PASS_FILE = "/run/secrets/password";
        };

        extraOptions = [
          "--cap-drop=ALL"

          # for nginx
          "--cap-add=CHOWN"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--cap-add=DAC_OVERRIDE"
          "--subuidname=root"
          "--subgidname=root"
        ];
      };
    })
  ];
}
