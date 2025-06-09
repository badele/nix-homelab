{ lib, ... }:
let
  homelabJson = builtins.fromJSON (builtins.readFile ../../../../homelab.json);

  # Network options
  netOptions = with lib; {
    vlanId = mkOption {
      type = types.int;
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
in
{
  options = with lib; {
    homelab.domain = mkOption {
      type = types.str;
      default = null;
      description = "Domain";
    };
    homelab.networks = mkOption {
      type = with types; attrsOf (submodule [{ options = netOptions; }]);
      description = "Networks";
    };

    homelab.borgBackup.remote = mkOption {
      type = types.str;
      default = null;
      description = "Borg backup remote server address (ssh://address:port)";
    };
  };

  config = {
    homelab.domain = homelabJson.domain;
    homelab.networks = homelabJson.networks;
    homelab.borgBackup.remote = homelabJson.borgBackup.remote;
  };
}
