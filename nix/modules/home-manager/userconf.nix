{ lib, config, ... }:

with lib;
{
  options = {
    home.userconf = {
      user = {
        gpg = {
          id = mkOption {
            type = types.str;
            description = ''
              Public GPG key
            '';
          };

          url = mkOption {
            type = types.str;
            default = "";
            example = "https://keybase.io/username/pgp_keys.asc";
            description = "Link to the public GPG key";
          };

          sha256 = mkOption {
            type = types.str;
            default = "";
            example = "sha256:1hr53gj98cdvk1jrhczzpaz76cp1xnn8aj23mv2idwy8gcwlpwlg";
            description = "The sha256 of the myconf.user.gpg.url content";
          };
        };
      };
    };
  };
}
