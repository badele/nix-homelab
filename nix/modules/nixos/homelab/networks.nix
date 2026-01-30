{ lib, config, ... }:
let
  netOptions = with lib;
    with types; {
      vlanId = mkOption {
        type = nullOr int;
        default = null;
        description = "VLAN ID";
      };

      net = mkOption {
        type = types.str;
        default = null;
        description = "network";
      };

      mask = mkOption {
        type = types.int;
        default = null;
        description = "mask";
      };
    };
in {
  options = with lib; {
    homelab.networks = mkOption {
      type = with types; attrsOf (submodule [{ options = netOptions; }]);
      description = "Networks";
    };
  };
}
