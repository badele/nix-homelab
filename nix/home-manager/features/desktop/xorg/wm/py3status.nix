{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.python310Packages.py3status
  ];

  xdg.configFile."py3status.conf".text = ''
    general {
        output_format = i3bar
        colors = true
        color_good = "#859900"
        interval = 1
    }
    order += "external_script current_task"
    order += "external_script inbox"
    order += "spotify"
    order += "wireless wlp59s0"
    order += "ethernet enp3s0f0"
    order += "cpu_usage"
    order += "battery 0"
    order += "audiosink"
    order += "volume_status"
    order += "keyboard_layout"
    order += "time"
    mpd {
        format = "%artist - %album - %title"
    }
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
    time {
        format = "⌚ %a %h %d  %I:%M     "
    }
    spotify {
        color_playing = "#fdf6e3"
        color_paused = "#93a1a1"
        format_stopped = ""
        format = "{title} - {artist} ({album})"
        format_stopped = "[Paused] {title} - {artist} ({album})"
        format_down = ""
    }
    audiosink {
        display_name_mapping = {
            "Nor-Tec streaming mic Analog Stereo": "USB", 
            "Built-in Audio Analog Stereo": "INT", 
            "Simultaneous output to Nor-Tec streaming mic Analog Stereo, Built-in Audio Analog Stereo": "MIX"
        }
        format = "🎧 {audiosink}"
        sinks_to_ignore = [""]
        separator = false
    }
    volume_status {
        format = "{percentage}%"
    }
  '';
}
