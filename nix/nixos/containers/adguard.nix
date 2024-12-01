{ lib, config, ... }:
let

  hostAddress =
    (builtins.elemAt config.networking.interfaces."br-adm".ipv4.addresses
      0).address;
  defaultGateway =
    (builtins.elemAt config.networking.interfaces."br-adm".ipv4.routes 0).via;

in
{

  # networking.vswitches = { br-adm = { interfaces = { vb-adguard = { }; }; }; };

  containers.adguard = {
    autoStart = true;
    privateNetwork = true;
    # hostBridge = "br-adm";
    hostAddress = hostAddress;
    localAddress = "192.168.240.96";

    # container service
    config = lib.recursiveUpdate
      (import ../services/adguard.nix { inherit lib config; })
      {

        networking.useDHCP = false;
        networking.defaultGateway = defaultGateway;
      };
  };
}
