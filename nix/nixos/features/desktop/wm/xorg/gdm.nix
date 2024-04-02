{ config, lib, pkgs, ... }:
{

  imports = [
  ];

  programs.dconf.enable = true;
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager = {
      gdm.enable = true;
      defaultSession = config.hostprofile.autologin.session;
      autoLogin.user = config.hostprofile.autologin.user;
    };

    # INFO: Keyboard layout and touchpad are configured in ./nixos/features/commons/locale.nix
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gnome-terminal
    gedit # text editor
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);

}
