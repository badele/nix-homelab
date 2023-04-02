{ pkgs, ... }:
{
  imports = [
    ./kitty.nix
    ./mako.nix
    ./swayidle.nix
    ./swaylock.nix
    ./waybar.nix
    ./wofi.nix
  ];

  programs.wezterm.enable = true;

  home.packages = with pkgs; [
    swaylock # lockscreen
    swayidle # power off
    xwayland # legacy apps
    xdg-utils # xdg-open
    xdg-desktop-portal # native dialog support
    waybar # wayland polybar alternative
    wl-clipboard # clipboard
    wofi # rofi alternative
    wf-recorder # screen recorder
    mako # notification
    kanshi # wayland autorandr alternative
    imv # Images viewer
    mimeo # mimeo / TODO persist configuration ? /home/badele/.config/mimeapps.list
    #flameshot # TODO: Screenshot
    grim # screenshot
    slurp # screenshot
    wev # Show keycode pressed
    wl-mirror # Output mirror
    wl-mirror-pick # Output mirror

    # Multimedia
    mpv # Video player
    celluloid # mpv frontend
    cava #vumeter
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = true;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };
}
