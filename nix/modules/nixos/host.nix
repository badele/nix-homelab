{ lib, config, ... }:

with lib; with types;
{
  options = {
    hostprofile = {
      nproc = mkOption {
        type = int;
        default = 4;
        description = ''
          Nb logical processors
        '';
      };
      autologin = {
        user = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Session autologin (X destkop)
          '';
        };
        session = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Session type
          '';
        };
      };
    };
  };
}
