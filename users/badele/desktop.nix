{
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home-manager/desktop/apps/base.nix

    # Desktop Apps
    # ../../home-manager/desktop/apps/cad.nix
    # ../../home-manager/desktop/apps/chess.nix
    ../../modules/home-manager/desktop/apps/graphics.nix
    ../../modules/home-manager/desktop/apps/offices.nix
    ../../modules/home-manager/desktop/apps/musics.nix
    # ../../home-manager/desktop/apps/vscode.nix

    # Web browser
    # ../../home-manager/desktop/apps/google-chrome.nix
    ../../users/badele/modules/firefox.nix
  ];

  stylix.fonts = {
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    monospace = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
  };

  # Avoid activation failures when legacy GTK files already exist on disk.
  xdg.configFile."gtk-3.0/gtk.css".force = true;
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;

  home.packages = with pkgs; [
    hl-log-viewer # JSON and logfmt viewer
  ];
}
