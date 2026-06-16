{ pkgs, ... }:
{
  imports = [
    # Theme
    ./fonts.nix
    ./gtk.nix
    ./qt.nix

    # Multimedia
    ./playerctl.nix
    ./audio/pipewire.nix

    # Misc
    ./wpa-gui.nix
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.kde.okular.desktop" ];
    };
  };

  home.packages = with pkgs; [
    arandr
    meld
  ];
}
