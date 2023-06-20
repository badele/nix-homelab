{ config, lib, pkgs, ... }:
let
  hexPalette = with pkgs.lib.nix-rice; palette.toRGBHex pkgs.rice.colorPalette;

  grep = (lib.getBin pkgs.gnugrep) + "/bin/grep";
  bash = (lib.getBin pkgs.bash) + "/bin/bash";
  echo = (lib.getBin pkgs.coreutils) + "/bin/echo";
  awk = (lib.getBin pkgs.gawk) + "/bin/awk";
  pactl = (lib.getBin pkgs.pulseaudio) + "/bin/pactl";

in
{
  xdg.dataFile."bin/i3status-toggle-pulseaudio-output" = {
    executable = true;

    text = ''
      #!${bash}

      echo "ON ENTER" >> /tmp/audio.log
  

      set -e

      export LC_ALL=C

      current_output=$(${pactl} info | ${grep} 'Default Sink:' | ${awk} '{print $3}')
      next_output=$(${pactl} list short sinks | ${grep} alsa_output | ${grep} -v $current_output)
      next_output_name=$(${echo} $next_output | ${awk} '{print $2}')

      echo $current_output >> /tmp/audio.log
      echo $next_output >> /tmp/audio.log
      echo $next_output_name >> /tmp/audio.log

      ${pactl} set-default-sink $next_output_name
    '';
  };

  programs.i3status-rust = {
    enable = true;

    bars = {
      top = {
        theme = "modern";
        icons = "awesome6";
        settings.theme = {
          overrides = {
            idle_bg = "${hexPalette.background}";
            idle_fg = "${hexPalette.bright.white}";
            info_bg = "${hexPalette.dark-bright.blue}";
            info_fg = "${hexPalette.bright.white}";
            good_bg = "${hexPalette.dark-normal.green}";
            good_fg = "${hexPalette.bright.white}";
            warning_bg = "${hexPalette.dark-bright.yellow}";
            warning_fg = "${hexPalette.bright.white}";
            critical_bg = "${hexPalette.dark-bright.red}";
            critical_fg = "${hexPalette.bright.white}";

            separator = "";
            #     #separator = "\ue0b2";
            #     separator_bg = "auto";
            #     separator_fg = "auto";
            alternating_tint_bg = "#111111";
            alternating_tint_fg = "#111111";
          };
        };

        blocks = [
          # Spotify
          {
            block = "music";
            player = "spotify";
            format = " $icon $volume_icon $combo $prev $play $next| ";
            click = [
              {
                button = "up";
                action = "volume_up";
              }
              {
                button = "down";
                action = "volume_down";
              }
            ];
          }
          {
            block = "cpu";
            interval = 1;
            format = " $icon $barchart $utilization ";
            format_alt = " $icon $frequency{ $boost|} ";
          }
          {
            block = "load";
            format = " $icon $5m ";
            interval = 1;
          }
          {
            block = "memory";
            format = " $icon $mem_used_percents ";
            format_alt = " $icon $swap_used_percents ";
          }
          #   {
          #     block = "custom";
          #     command = "echo ' ' `curl ifconfig.me`"; # assumes fontawesome icons
          #     interval = 60;
          #   }
          {
            block = "net";
            format = " $icon {$signal_strength $ssid ^icon_net_down $speed_down $graph_down ^icon_net_up $speed_up $graph_up |Eth ^icon_net_down $speed_down $graph_down ^icon_net_up $speed_up $graph_up} ";
          }
          # Ping latency
          {
            block = "custom";
            json = true;
            command = ''echo "{\"icon\":\"ping\",\"text\":\"`ping -c4 1.1.1.1 | tail -n1 | cut -d'/' -f5`\"}" | tee -a /tmp/ping'';
            interval = 60;
            click = [
              {
                button = "left";
                update = true;
                cmd = "<command>";
              }
            ];
          }
          # {
          #   block = "backlight";
          #   device = "intel_backlight";
          #   minimum = 15;
          #   maximum = 100;
          #   cycle = [ 100, 50, 15, 50 ];
          # }
          {
            block = "sound";
            format = "$icon $output_name {$volume.eng(w:2) |}";
            click = [
              {
                button = "left";
                cmd = ''~/${config.xdg.dataFile."bin/i3status-toggle-pulseaudio-output".target}'';
              }
            ];

            #pactl list short sink
            mappings =
              {
                "alsa_output.usb-MUSIC-BOOST_Nor-Tec_streaming_mic_ES329-00.analog-stereo" = "USB";
                "alsa_output.pci-0000_00_1f.3.analog-stereo" = "INT";
              };
          }
          # Weather
          {
            block = "custom";
            command = "sed 's/  //' <(curl -s 'https://wttr.in/?format=2')";
            interval = 600;
          }
          {
            block = "time";
            format = " $timestamp.datetime(f:'%a %d/%m %R') ";
            interval = 60;
          }
          {
            block = "notify";
            format = " $icon {$paused{Off}|On} ";
          }
        ];
      };
      #   settings =
      #     {
      #       theme = {
      #         theme = "solarized-dark";
      #         overrides = {
      #           idle_bg = "#123456";
      #           idle_fg = "#abcdef";
      #         };
      #       };
      #     };

    };
  };
}

