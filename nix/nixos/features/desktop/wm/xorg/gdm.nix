{
  config,
  lib,
  pkgs,
  ...
}:
{

  imports = [
  ];

  programs.dconf.enable = true;
  services.xserver = {
    enable = true;

    # INFO: Keyboard layout and touchpad are configured in ./nixos/features/commons/locale.nix
  };

  services.desktopManager.gnome.enable = true;

  services.displayManager = {
    gdm.enable = true;
    defaultSession = config.hostprofile.autologin.session;
    autoLogin = {
      enable = true;
      user = config.hostprofile.autologin.user;
    };
  };

  environment.gnome.excludePackages = (
    with pkgs;
    [
      cheese # webcam tool
      gnome-photos
      gnome-tour
      gedit # text editor
      gnome-music
      gnome-terminal
      epiphany # web browser
      geary # email reader
      evince # document viewer
      gnome-characters
      totem # video player
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
    ]
  );

}
