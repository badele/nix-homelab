{ config, lib, pkgs, ... }:

let
  inherit (pkgs.lib) optionals optional;
  inherit (config.colorscheme) colors kind;

  # Dependencies
  binpath = "~/.nix-profile";
  statusweather = "${binpath}/bin/status-weather";
  statuscava = "${binpath}/bin/status-cava";
  jq = "${pkgs.jq}/bin/jq";
  xml = "${pkgs.xmlstarlet}/bin/xml";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";

  # Function to simplify making waybar outputs
  jsonOutput = name: { pre ? "", text ? "", tooltip ? "", alt ? "", class ? "", percentage ? "" }: "${pkgs.writeShellScriptBin "waybar-${name}" ''
    set -euo pipefail
    ${pre}
    ${jq} -cn \
      --arg text "${text}" \
      --arg tooltip "${tooltip}" \
      --arg alt "${alt}" \
      --arg class "${class}" \
      --arg percentage "${percentage}" \
      '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
  ''}/bin/waybar-${name}";
in
{
  programs.waybar = {
    enable = true;
    settings = {

      primary = {
        mode = "dock";
        layer = "top";
        height = 38;
        margin = "4";
        position = "top";
        output = builtins.map (m: m.name) (builtins.filter (m: m.isSecondary == false) config.monitors);
        modules-left = [
          "custom/currentplayer"
          "custom/player"
          "custom/cava"
        ];
        modules-center = [
          "clock"
          "custom/weather"
          "custom/gpg-agent"
        ];
        modules-right = [
          #"custom/tailscale-ping"
          #          "custom/hostname"
          "network"
          "pulseaudio"
          "backlight"
          "battery"
          #"tray"

        ];

        clock = {
          locale = "fr_FR.UTF-8";
          timezone = "Europe/Paris";
          format = "{:%a, %d %b -  %H:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          today-format = "<span color='#${colors.base08}'><b>{}</b></span>";
        };

        "custom/weather" = {
          format = "{}";
          tooltip = true;
          interval = 1800;
          exec = "${statusweather}";
          return-type = "json";
        };

        pulseaudio = {
          reverse-scrolling = 1;
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = "婢 {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "奄" "奔" "墳" ];
          };
          on-click = "pavucontrol";
          min-length = 13;
        };

        backlight =
          {
            device = "intel_backlight";
            format = "{icon} {percent}%";
            format-icons = [ "" ];
          };

        battery = {
          bat = "BAT0";
          interval = 10;
          format-icons = [ "" "" "" "" "" "" "" "" "" "" ];
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          states = {
            warning = 30;
            critical = 15;
          };
        };

        tray = {
          icon-size = 16;
          spacing = 0;
        };

        "sway/window" = {
          max-length = 20;
        };

        network = {
          interval = 3;
          format-wifi = "   {essid}";
          format-ethernet = " Connected";
          format-disconnected = "";
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}'';
        };

        "custom/tailscale-ping" = {
          interval = 2;
          return-type = "json";
          exec =
            let
              targets = {
                electra = { host = "electra"; icon = " "; };
                merope = { host = "merope"; icon = " "; };
                atlas = { host = "atlas"; icon = " "; };
                maia = { host = "maia"; icon = " "; };
                pleione = { host = "pleione"; icon = " "; };
              };

              showPingCompact = { host, icon }: "${icon} $ping_${host}";
              showPingLarge = { host, icon }: "${icon} ${host}: $ping_${host}";
              setPing = { host, ... }: ''
                ping_${host}="$(timeout 2 ping -c 1 -q ${host} 2>/dev/null | tail -1 | cut -d '/' -f5 | cut -d '.' -f1)ms" || ping_${host}="Disconnected"
              '';
            in
            jsonOutput "tailscale-ping" {
              pre = ''
                set -o pipefail
                ${builtins.concatStringsSep "\n" (map setPing (builtins.attrValues targets))}
              '';
              text = "${showPingCompact targets.electra} / ${showPingCompact targets.merope}";
              tooltip = builtins.concatStringsSep "\n" (map showPingLarge (builtins.attrValues targets));
            };
          format = "{}";
        };

        "custom/menu" = {
          return-type = "json";
          exec = jsonOutput "menu" {
            text = "";
            tooltip = ''$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)'';
          };
        };
        "custom/hostname" = {
          exec = "echo $USER@$(hostname)";
        };

        "custom/gpg-agent" = {
          interval = 2;
          return-type = "json";
          exec =
            let keyring = import ../../keyring.nix { inherit pkgs; };
            in
            jsonOutput "gpg-agent" {
              pre = ''status=$(${keyring.isUnlocked} && echo "unlocked" || echo "locked")'';
              alt = "$status";
              tooltip = "GPG is $status";
            };
          format = "{icon}";
          format-icons = {
            "locked" = "";
            "unlocked" = "";
          };
        };

        "custom/gpu" = {
          interval = 5;
          return-type = "json";
          exec = jsonOutput "gpu" {
            text = "$(cat /sys/class/drm/card0/device/gpu_busy_percent)";
            tooltip = "GPU Usage";
          };
          format = "力  {}%";
        };

        "custom/currentplayer" = {
          interval = 2;
          return-type = "json";
          exec = jsonOutput "currentplayer" {
            pre = ''player="$(${playerctl} status -f "{{playerName}}" 2>/dev/null || echo "No players found" | cut -d '.' -f1)"'';
            alt = "$player";
            tooltip = "$player";
          };
          format = "{icon}";
          format-icons = {
            "No players found" = "ﱘ";
            "Celluloid" = "";
            "spotify" = "";
            "firefox" = "";
            "discord" = "ﭮ";
          };
          on-click = "${playerctld} shift";
          on-click-right = "${playerctld} unshift";
        };

        "custom/player" = {
          exec-if = "${playerctl} status";
          exec = ''${playerctl} metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
          return-type = "json";
          interval = 2;
          max-length = 30;
          format = "{icon} {}";
          format-icons = {
            "Playing" = "契";
            "Paused" = " ";
            "Stopped" = "栗";
          };
          on-click = "${playerctl} play-pause";
        };

        "custom/cava" = {
          exec = ''${statuscava}'';
          restart-interval = 5;
          return-type = "newline";
          max-length = 30;
        };

      };

      secondary = {
        mode = "dock";
        layer = "top";
        height = 32;
        #        width = 100;
        margin = "4";
        position = "bottom";
        modules-left = (optionals config.wayland.windowManager.sway.enable [
          "sway/workspaces"
          "sway/mode"
        ]) ++ (optionals config.wayland.windowManager.hyprland.enable [
          "wlr/workspaces"
        ]);

        modules-right = [
          "temperature"
          "custom/gpu"
          "cpu"
          "memory"
        ];

        # "wlr/workspaces" = {
        #   on-click = "activate";
        # };

        "wlr/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "1:  MUS";
            "2" = "2:  TERM";
            "3" = "3:  CHAT";
            "4" = "4:  VIRT";
            "5" = "5:  GFX";
            "6" = "6:  MISC";
            "7" = "7:  WWW";
            "8" = "8:  TERM";
            "9" = "9:  DEV";
            "10" = "0:  TERM";
            urgent = "";
            #active = "";
            #default = "";
          };
          sort-by-number = true;
        };


        # cpu = {
        #   interval = 1;
        #   format = " {usage}%";
        # };

        cpu =
          let
            # show nproc CPU bars
            icons = lib.concatMapStrings (x: "{icon" + toString x + "} ") (lib.range 0 (config.hostprofile.nproc - 1));
          in
          {
            interval = 1;
            format = "${icons} {usage:>2}%";
            format-icons = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
            states = {
              warning = 70;
              critical = 90;
            };
          };

        # see sensors command
        temperature = {
          format = "  {temperatureC:>2}°C";
          hwmon-path = config.hostprofile.coretemp;
          critical-threshold = 80;
        };

        memory = {
          format = "  {}%";
          interval = 5;
          states = {
            warning = 70;
            critical = 90;
          };
        };

      };


    };
    # DEBUGING STYLE
    # env GTK_DEBUG=interactive waybar
    # waybar -l debug

    style =
      let inherit (config.colorscheme) colors; in
      ''
          
          
          * {
            border: none;
            border-radius: 0;
            font-family: Liberation Mono;
            min-height: 20px;
          }

          window#waybar {
            background: transparent;
          }

          window#waybar.hidden {
            opacity: 0.2;
          }

          #workspaces {
            margin-right: 8px;
            border-radius: 10px;
            /*transition: none;*/
            background: #${colors.base02};
          }

          #workspaces button {
            /*transition: none;*/
            color: #${colors.base07};
            background: transparent;
            padding: 5px;
          }

          #workspaces button.active {
            background: #${colors.base0F};
            color: #${colors.base07};
          }          

          #pulseaudio,
          #network,
          #backlight,
          #battery
           {
              margin-right: 8px;
              padding-left: 16px;
              padding-right: 16px;
              border-radius: 10px;
              /*transition: none;*/
              color: #${colors.base07};
              background: #${colors.base02};
          }


          #clock
          {
            padding-left: 16px;
            padding-right: 16px;
            border-radius: 10px 0px 0px 10px;
            color: #${colors.base07};
            background: #${colors.base02};
          }          

          #custom-weather,
          #memory {
            padding-right: 16px;
            border-radius: 0px 10px 10px 0px;
            /*transition: none;*/
            color: #${colors.base07};
            background: #${colors.base02};
          }        

          #custom-currentplayer
          {
            padding-left: 16px;
            padding-right: 16px;
            border-radius: 10px 0px 0px 10px;
            font-size: 24px;
            color: #${colors.base07};
            background: #${colors.base02};
          }          

          #custom-player
          {
            padding-right: 16px;
            border-radius: 0px 0px 0px 0px;
            /*transition: none;*/
            color: #${colors.base07};
            background: #${colors.base02};
          }        

          #custom-cava
          {
            padding-right: 16px;
            border-radius: 0px 10px 10px 0px;
            /*transition: none;*/
            color: #${colors.base07};
            background: #${colors.base02};
          }        


          #cpu {
            padding-left: 16px;
            padding-right: 16px;
            border-radius: 0px 0px 0px 0px;
            color: #${colors.base07};
            background: #${colors.base02};
          }          

          #cpu.warning {
            color: #${colors.base09};
          }          

          #cpu.critical {
            color: #${colors.base08};
          }          

          #temperature {
            padding-left: 16px;
            padding-right: 16px;
            border-radius: 10px 0px 0px 10px;
            color: #${colors.base07};
            background: #${colors.base02};
          }          

          #memory.warning {
            color: #${colors.base09};
          }          

          #memory.critical {
            color: #${colors.base08};
          }          


          #battery.charging {
              color: #${colors.base07};
              background-color: #${colors.base0B};
          }

          #battery.warning:not(.charging) {
              background-color: #${colors.base09};
              color: black;
          }

          #battery.critical:not(.charging) {
              background-color: #${colors.base08};
              color: #${colors.base07};
              animation-name: blink;
              animation-duration: 0.5s;
              animation-timing-function: linear;
              animation-iteration-count: infinite;
              animation-direction: alternate;
          }

          #pulseaudio.muted {
            color: #${colors.base08};
            background: #${colors.base02};
          }

        #tray {
            padding-left: 16px;
            padding-right: 16px;
            border-radius: 10px;
            /*transition: none;*/
            color: #${colors.base07};
            background: #${colors.base02};
        }

        #custom-hostname {
          background-color: #${colors.base02};
          color: #${colors.base05};
          padding-left: 15px;
          padding-right: 18px;
          margin-right: 0;
          margin-top: 0;
          margin-bottom: 0;
          border-radius: 10px;
        }
      '';
  };
}

