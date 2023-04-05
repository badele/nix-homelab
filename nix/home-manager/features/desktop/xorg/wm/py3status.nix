{ config, lib, pkgs, ... }:
let
  inherit (config) colorscheme;
  inherit (colorscheme) colors;
in
{
  home.packages = [
    pkgs.python310Packages.py3status
  ];

  xdg.configFile."py3status.conf".text = ''
    general {
        output_format = i3bar
        colors = true
        color_good = "#${colors.base0B}"
        color_bad = "#${colors.base08}"
        interval = 1
    }
    order += "spotify"
    order += "wireless wlp59s0"
    order += "online_status"
    order += "ethernet enp3s0f0"
    order += "vpn_status"
    order += "cpu_usage"
    order += "load"
    order += "battery 0"
    order += "yubikey"
    order += "audiosink"
    order += "volume_status"
    order += "backlight"
    order += "keyboard_layout"
    order += "keyboard_locks"
    order += "pomodoro"
    order += "dpms"
    order += "do_not_disturb"
    order += "clock"
    wireless wlp59s0 {
        format_up = "W: %essid / %ip"
        format_down = "W: -"
    }
    ethernet enp3s0f0 {
        format_up = "E: %ip"
        format_down = "E: -"
    }
    battery 0 {
        format = "%status %percentage"
        path = "/sys/class/power_supply/BAT%d/uevent"
        low_threshold = 10
    }
    cpu_usage {
        format = "CPU: %usage"
    }
    load {
        format = "%5min"
    }
    keyboard_layout {
    }

    clock {
        block_hours = 24
        format = ["{Europe/Paris}", "{America/New_York}", "{Asia/Tokyo}"]
        format_time = "{icon} {name} %a %d %b %H:%M"
    }
    spotify {
        color_playing = "#fdf6e3"
        color_paused = "#93a1a1"
        format = "🎵 {title} - {artist} ({album})"
        format_stopped = "[Paused] {title} - {artist} ({album})"
        format_down = ""
    }
    audiosink {
        display_name_mapping = {
            "Nor-Tec streaming mic Stéréo analogique": "USB", 
            "Audio interne Stéréo analogique": "INT"
        }
        format = "🎧 {audiosink}"
        sinks_to_ignore = [""]
        separator = false
    }
    volume_status {
        format = "{percentage}%"
    }
    backlight {
        format = "☼: {level}%"
    }
    do_not_disturb {
        format = 'NTFY [\?color=state [\?if=state  OFF|ON]]'
    }
    dpms {

    }
    keyboard_locks {
        format = '\?color=good [\?if=num_lock NUM][\?soft  ]'
        format += '[\?if=caps_lock CAPS]'
    }
    online_status {

    }
    pomodoro {

    }
    vpn_status {

    }
    yubikey {

    }
  '';
}
