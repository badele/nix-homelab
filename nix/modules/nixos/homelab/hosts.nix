{ lib, config, ... }:
let
  hostOptions = with lib;
    with types; {
      icon = mkOption {
        type = str;
        default = null;
        description = ''
          host icon
        '';
      };

      description = mkOption {
        type = str;
        default = null;
        description = ''
          host description
        '';
      };

      zone = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          Zone localisation
        '';
      };

      parent = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          network link
        '';
      };

      hostIpId = mkOption {
        type = nullOr int;
        default = null;
        description = ''
          host IP id (for computing the host IP address in VLAN network)
        '';
      };

      ipv4 = mkOption {
        type = str;
        description = ''
          own ipv4 address
        '';
      };

      wg = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          wireguard ipv4 address
        '';
      };

      dnsalias = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = ''
          dnsalias for this host
        '';
      };

      os = mkOption {
        type = str;
        default = null;
        description = ''
          OS
        '';
      };

      nproc = mkOption {
        type = int;
        description = ''
          Nb logical processors
        '';
      };

      autologin = mkOption {
        type = with types;
          nullOr (submodule {
            options = {
              user = mkOption {
                type = nullOr str;
                default = null;
                description = "Session autologin (X desktop)";
              };

              session = mkOption {
                type = nullOr str;
                default = null;
                description = "Session type";
              };
            };
          });

        default = null;
        description = "Autologin configuration (optional)";
      };

      roles = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = ''
          role names to be install
        '';
      };

      params = mkOption {
        type = attrs;
        default = { };
        description = ''
          Paramètres arbitraires personnalisés pour cet hôte.
        '';
      };
    };
in {
  options = with lib;
    with types; {
      homelab.networkId = mkOption {
        type = int;
        description = "Network ID";
      };

      homelab.hosts = mkOption {
        type = attrsOf (submodule [{ options = hostOptions; }]);
        description = "A host in my homelab";
      };

      homelab.currentHost = mkOption {
        type = submodule [{ options = hostOptions; }];
        default = config.homelab.hosts.${config.networking.hostName};
        description = "The host that is described by this configuration";
      };
    };

  config = {
    warnings =
      lib.optional (!(config.homelab.hosts ? ${config.networking.hostName}))
      "no network configuration for ${config.networking.hostName} found in ${
        ./hosts.nix
      }";

    # Read from ../../../../homelab.json
    # TODO: verify if this file build too many derivations
    homelab.hosts =
      (builtins.fromJSON (builtins.readFile ../../../../homelab.json)).hosts;
  };
}
