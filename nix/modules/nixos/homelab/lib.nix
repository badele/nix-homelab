{ lib, ... }:

let
  # Compute the network host address based on the network and host ID.
  computeNetworkHostAddress = net: hostIpId:
    let parts = lib.strings.splitString "." net;
    in lib.strings.concatStringsSep "."
    ((lib.lists.init parts) ++ [ (toString hostIpId) ]);
in {
  options.homelab = {
    lib = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Library functions for homelab.";
    };
  };

  config.homelab.lib = { inherit computeNetworkHostAddress; };
}
