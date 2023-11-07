{ pkgs, lib, outputs, ... }:
{
  imports = [
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
  ];
}
