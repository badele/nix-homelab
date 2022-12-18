{ lib
, config
, ...
}:
let
  hostOptions = with lib; {
    icon = mkOption {
      type = types.str;
      default = null;
      description = ''
        host icon
      '';
    };

    description = mkOption {
      type = types.str;
      default = null;
      description = ''
        host description
      '';
    };

    ipv4 = mkOption {
      type = types.str;
      description = ''
        own ipv4 address
      '';
    };

    alias = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        alias for this host
      '';
    };

    discovery = mkOption {
      type = types.listOf types.str;
      default = null;
      description = ''
        discovery mode
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
