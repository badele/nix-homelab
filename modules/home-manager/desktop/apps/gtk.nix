{ config, pkgs, ... }:
rec {
  gtk.enable = true;
  gtk.iconTheme.name = "Papirus";
  gtk.iconTheme.package = pkgs.papirus-icon-theme;
  gtk.gtk4.theme = null;

  services.xsettingsd.enable = true;
  services.xsettingsd.settings = {
    "Net/IconThemeName" = "${gtk.iconTheme.name}";
  };
}
