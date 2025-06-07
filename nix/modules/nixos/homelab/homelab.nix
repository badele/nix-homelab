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

    # Borgbackup options
    borgOptions = with lib; {
      address = mkOption {
        type = types.str;
        default = null;
        description = "Borg backup remote server address";
      };
      port = mkOption {
        type = types.int;
        default = 22; # Port SSH par défaut pour Borg
        description = "Borg backup remote server port";
      };
      users = mkOption {
        type = with types; listOf (submodule [{ options = borgUserOptions; }]);
        default = [ ];
        description = "Borg backup users mapped";
      };
    };

    # User options
    borgUserOptions = with lib; {
      netbox = mkOption {
        type = types.str;
        default = null;
        description = "Mapper user for Borg backup";
      };
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

    homelab.borgBackup = mkOption {
      type = with types; attrsOf (submodule [{ options = borgOptions; }]);
      description = "Borg Backup";
    };

  };

  config = {
    homelab.domain = homelabJson.domain;
    homelab.networks = homelabJson.networks;
    homelab.borgBackup = homelabJson.borgBackup;
  };
}
