{ lib
, config
, ...
}:
{
  options = with lib; {
    homelab.domain = mkOption {
      type = types.str;
      default = null;
      description = "Domain";
    };
  };

  config = {
    # Read from ../../../homelab.json
    # TODO: verify if this file build too many dependencies derivations
    homelab.domain = (builtins.fromJSON (builtins.readFile ../../../homelab.json)).domain;
  };
}
