{ config
, inputs
, lib
, pkgs
, sops
, ...
}: {

  imports = [
  ];

  home.packages = with pkgs; [
    spotify
    # spotify-tui
    ncspot
    playerctl
  ];

  services = {
    playerctld = {
      enable = true;
    };

    # Used by
    spotifyd = {
      enable = true;
      settings = {
        global = {
          username_cmd = "${pkgs.coreutils}/bin/cat /run/secrets/spotify/user";
          password_cmd = "${pkgs.coreutils}/bin/cat /run/secrets/spotify/password";
          device_name = "nix";
        };
      };
    };
  };

  # sops.secrets."spotify/user" = {
  #   sopsFile = ../../users/badele/secrets.yml;
  #   neededForUsers = true;
  # };

  # sops.secrets."spotify/password" = {
  #   sopsFile = ../../users/badele/secrets.yml;
  #   neededForUsers = true;
  # };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [
  #     ".config/spotify"
  #     ".config/ncspot"
  #   ];
  # };
}
