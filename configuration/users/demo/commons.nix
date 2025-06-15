{ config, pkgs, lib, ... }: {
  ##############################################################################
  # Common user conf
  ##############################################################################
  home = {
    username = lib.mkDefault "demo";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    userconf = {
      user = {
        gpg = {
          id = "00F421C4C5377BA39820E13F6B95E13DE469CC5D";
          url = "https://keybase.io/brunoadele/pgp_keys.asc";
          sha256 =
            "sha256:1hr53gj98cdvk1jrhczzpaz76cp1xnn8aj23mv2idwy8gcwlpwlg";
        };
      };
    };

    stateVersion = lib.mkDefault "22.11";
  };

  programs.git.enable = true;

  ##############################################################################
  # Packages
  ##############################################################################
  home.packages = with pkgs; [
    nano
    xclip
  ];
}
