{ lib
, config
, ...
}:
let
  netOptions = with lib; {
    net = mkOption {
      type = types.str;
      default = null;
      description = ''
        network
      '';
    };

    mask = mkOption {
      type = types.int;
      default = null;
      description = ''
        mask
      '';
    };
  };
in
{
  options = with lib; {
    networking.homelab.networks = mkOption {
      type = with types; attrsOf (submodule [{ options = netOptions; }]);
      description = "Networks";
    };
  };

  config = {
    # Read from ../../homelab.json
    # TODO: verify if this file build too many dependencies derivations
    networking.homelab.networks = (builtins.fromJSON (builtins.readFile ../../homelab.json)).networks;
  };
}
