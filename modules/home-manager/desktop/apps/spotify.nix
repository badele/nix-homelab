{
  pkgs,
  ...
}:
{

  imports = [
  ];

  home.packages = with pkgs; [
    spotify
    # spotify-tui
    ncspot
    playerctl
  ];

  services.playerctld.enable = true;

  # Used by
  services.spotifyd.enable = true;
  services.spotifyd.settings.global.username_cmd =
    "${pkgs.coreutils}/bin/cat /run/secrets/spotify/user";
  services.spotifyd.settings.global.password_cmd =
    "${pkgs.coreutils}/bin/cat /run/secrets/spotify/password";
  services.spotifyd.settings.global.device_name = "nix";
}
