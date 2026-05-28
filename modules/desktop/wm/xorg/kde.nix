{
  lib,
  pkgs,
  inputs,
  options,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    xserver.xkb.layout = "fr";
  };

  environment.systemPackages = with pkgs; [
    # KDE Utilities
    kdePackages.qtstyleplugin-kvantum # Qt style plugin for Kvantum themes
    kdePackages.qttranslations # For French translations for KDE applications
    kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Character map
    kdePackages.kclock # Clock app
    kdePackages.kcolorchooser # Color picker
    kdePackages.kolourpaint # Simple paint program
    kdePackages.ksystemlog # System log viewer
    kdePackages.sddm-kcm # SDDM configuration module
    kdiff3 # File/directory comparison tool

    # Hardware/System Utilities (Optional)
    kdePackages.isoimagewriter # Write hybrid ISOs to USB
    kdePackages.partitionmanager # Disk and partition management
    kdePackages.plasma-nm # Network manager applet for Plasma
    kdePackages.print-manager # Print management for KDE
  ];

  # Clan can evaluate machine graphs where Home Manager is not loaded yet.
  # Guarding this avoids "The option `home-manager` does not exist" during clan select.
  home-manager = lib.mkIf (options ? home-manager) {
    users.badele.xdg.configFile."plasma-localerc" = {
      force = true;
      text = ''
        [Formats]
        LANG=fr_FR.UTF-8

        [Translations]
        LANGUAGE=fr_FR
      '';
    };

    users.sadele.xdg.configFile."plasma-localerc" = {
      force = true;
      text = ''
        [Formats]
        LANG=fr_FR.UTF-8

        [Translations]
        LANGUAGE=fr_FR
      '';
    };

    users.loadele.xdg.configFile."plasma-localerc" = {
      force = true;
      text = ''
        [Formats]
        LANG=fr_FR.UTF-8

        [Translations]
        LANGUAGE=fr_FR
      '';
    };

    users.luadele.xdg.configFile."plasma-localerc" = {
      force = true;
      text = ''
        [Formats]
        LANG=fr_FR.UTF-8

        [Translations]
        LANGUAGE=fr_FR
      '';
    };
  };
}
