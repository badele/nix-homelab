{ pkgs, ... }:
{
  imports = [
    # Theme
    ./fonts.nix
    ./gtk.nix
    ./qt.nix

    # Multimedia
    ./playerctl.nix
    ./pulseaudio.nix

    # Misc
    ./wpa-gui.nix
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    arandr
  ];
}
