{ lib, ... }:
let
  homelabJson = builtins.fromJSON (builtins.readFile ../../../../homelab.json);

in {
  options = with lib;
    with types; {
      homelab.domain = mkOption {
        type = str;
        default = null;
        description = "Domain";
      };

      homelab.borgBackup.remote = mkOption {
        type = types.str;
        default = null;
        description = "Borg backup remote server address (ssh://address:port)";
      };
    };

  config = with lib; {
    homelab.domain = homelabJson.domain;
    homelab.networks = homelabJson.networks;
    homelab.borgBackup.remote = homelabJson.borgBackup.remote;
  };
}
