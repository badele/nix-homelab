{ pkgs, lib, outputs, ... }:
{
  imports = [

    # Web browser
    ./google-chrome.nix

    # Theme
    ./gtk.nix
    ./qt.nix

    # Multimedia
    ./playerctl.nix
    ./pulseaudio.nix


    # Misc
    ./fonts.nix
    ./wezterm.nix
    ./wpa-gui.nix
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs ; [
    arandr
    discord
    file
    firefox
    gimp
    inkscape
    libreoffice
    mpv
    simplescreenrecorder
    gpick
  ];
}
