{ lib
, config
, ...
}:
let
  hostOptions = with lib; with types; {
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

    alias = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        alias for this host
      '';
    };

    os = mkOption {
      type = str;
      default = null;
      description = ''
        OS
      '';
    };

    modules = mkOption {
      type = nullOr (listOf str);
      default = null;
      description = ''
        module names to be install
      '';
    };

  };
in
{
  options = with lib; {
    networking.homelab.hosts = mkOption {
      type = with types; attrsOf (submodule [{ options = hostOptions; }]);
      description = "A host in my homelab";
    };
    networking.homelab.currentHost = mkOption {
      type = with types; submodule [{ options = hostOptions; }];
      default = config.networking.homelab.hosts.${config.networking.hostName};
      description = "The host that is described by this configuration";
    };
  };

  config = {
    warnings =
      lib.optional (!(config.networking.homelab.hosts ? ${config.networking.hostName}))
        "no network configuration for ${config.networking.hostName} found in ${./hosts.nix}";

    # Read from ../../homelab.json
    # TODO: verify if this file build too many derivations
    networking.homelab.hosts = (builtins.fromJSON (builtins.readFile ../../homelab.json)).hosts;
  };
}
