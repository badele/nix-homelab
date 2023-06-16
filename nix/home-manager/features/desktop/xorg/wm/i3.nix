{ config, lib, pkgs, ... }:

let
  cfg = config.xsession.windowManager.i3.config;
  hexPalette = with pkgs.lib.nix-rice; palette.toRGBHex pkgs.rice.colorPalette;
  lockTime = 4 * 60; # TODO: configurable desktop (10 min)/laptop (4 min)

  # i3 workspaces
  mod = "Mod4";
  w1 = "1:  TSK";
  w2 = "2:  MUS";
  w3 = "3:  CHAT";
  w4 = "4:  VIRT";
  w5 = "5:  TERM";
  w6 = "6:  GFX";
  w7 = "7:  WWW";
  w8 = "8:  TERM";
  w9 = "9:  DEV";
  w0 = "0:  TERM";

  # i3 parameters
  border = 1;
  gaps_inner = 5;
  gaps_outer = 5;
  gaps_top = 5;
  gaps_bottom = 5;


  playerctl = "${pkgs.playerctl}/bin/playerctl";
  flameshot = "${pkgs.flameshot}/bin/flameshot";
  peek = "${pkgs.peek}/bin/peek";
  gpick = "${pkgs.gpick}/bin/gpick";
  py3status = "${pkgs.python3Packages.py3status}/bin/py3status";
  feh = "${pkgs.feh}/bin/feh";
  i3lock = "${pkgs.i3lock-color}/bin/i3lock-color";
  xidlehook = "${pkgs.xidlehook}/bin/xidlehook";
  lockCmd = "${i3lock} --blur 5";
  terminal = "${pkgs.wezterm}/bin/wezterm";
in
{

  imports = [
    ./py3status.nix
  ];

  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = {
        modifier = mod;
        terminal = terminal;

        fonts = [ "Source Code Pro" "DejaVu Sans Mono, FontAwesome 6" ];
        colors = {
          focused = {
            background = hexPalette.normal.black;
            border = hexPalette.bright.magenta;
            childBorder = hexPalette.bright.magenta;
            indicator = hexPalette.bright.magenta;
            text = hexPalette.bright.white;
          };
          unfocused = {
            background = hexPalette.normal.black;
            border = hexPalette.normal.yellow;
            childBorder = hexPalette.normal.yellow;
            indicator = hexPalette.normal.yellow;
            text = hexPalette.bright.white;
          };
        };

        window = {
          titlebar = false;
          border = border;
        };

        focus = {
          newWindow = "smart";
        };

        gaps =
          {
            # Set inner/outer gaps
            outer = gaps_outer;
            inner = gaps_inner;
            top = gaps_top;
            bottom = gaps_bottom;
          };

        keybindings = {
          # Shortcut
          # || Super+Return || Launch new terminal | i3
          # || Super+Shift+r || Restart i3 | i3
          # || Super+q || Kill a window | i3
          # || Super+k || Show where is rocky | i3
          "${mod}+Return" = "exec ${cfg.terminal}";
          "${mod}+Shift+r" = "restart;
            exec notify-send 'i3 restarted'";
          "${mod}+q" = "kill";
          "${mod}+k" = "--release exec --no-startup-id //home/badele/private/projects/rokeys/rokeys";

          # # Lock screen
          # # || Super+l || Blurred screen lock | i3
          # # || Super+Ctrl+l || Screen lock with realtime output | i3
          "${mod}+l" = "exec ${lockCmd}";

          # # launch menu
          # # || Super+Space || Show rofi launcher | i3
          # # || Super+Ctrl+Space || Search rofi mode | i3
          # # || Super+Shift+e || Power and exit menu | i3
          "${mod}+space" = "exec --no-startup-id rofi -show-icons -show drun";

          # # Screenshot
          # # || Print || Take a desktop screenshot | i3
          # # || Shift+Print || Take a selection screenshot | i3
          # # || Super+c || Color picker | i3
          "Print" = "exec --no-startup-id ${flameshot} gui";
          "Shift+Print" = "--release exec --no-startup-id ${peek}";
          "${mod}+c" = "--release exec ${gpick}";

          # # Audio
          # # || Super+p || Pause media player | i3
          # # || Super+m || Show TUI pulseaudio mixer | i3
          # # || Super+d || Show TUI mount disk | i3
          "XF86AudioMute" = "exec --no-startup-id ~/.local/bin/mixer output mute";
          "XF86AudioMicMute" = "exec --no-startup-id ~/.local/bin/mixer mic mute";
          "XF86AudioLowerVolume" = "exec --no-startup-id ~/.local/bin/mixer output down";
          "XF86AudioRaiseVolume" = "exec --no-startup-id ~/.local/bin/mixer output up";
          "${mod}+p" = "exec --no-startup-id ${playerctl} play-pause";
          "${mod}+n" = "exec --no-startup-id ${playerctl} next";
          "${mod}+m" = "exec --no-startup-id ${cfg.terminal} start --class pulsemixer -- pulsemixer";
          "${mod}+d" = "exec --no-startup-id ${cfg.terminal} start --class bashmount -- bashmount";

          # # Screen brightness controls
          "XF86MonBrightnessUp" = "exec \"xbacklight -inc 10; notify-send 'brightness up'\"";
          "XF86MonBrightnessDown" = "exec \"xbacklight -dec 10; notify-send 'brightness down'\"";

          # # Video
          "${mod}+ctrl+r" = "exec --no-startup-id ~/.local/bin/video_toggle_record_desktop";

          # # Window focus
          # # || Super+Direction || Change focus | i3
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";
          "${mod}+Down" = "focus down";
          "${mod}+Left" = "focus left";

          # # Window movement
          # # || Super+Shift+Direction || Move window | i3
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Left" = "move left";

          # # Spliting
          # # || Super+h || Split horizontally | i3
          # # || Super+v || Split vertically | i3
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";

          # # floating and fullscreen
          # # || Super+Shift+Space || Float toggle window | i3
          # # || Super+s || Sticky toggle window | i3
          # # || Super+f|| Fullscreen window | i3
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+s" = "sticky toggle";
          "${mod}+f" = "fullscreen";

          # # Workspaces navigation
          # # || Super+Ctrl+Left || Previous workspace | i3
          # # || Super+Ctrl+Right || Next workspace| i3
          "${mod}+Ctrl+Right" = "workspace next";
          "${mod}+Ctrl+Left" = "workspace prev";

          # # Switch to workspace
          # # || Super+[0-9] || Select workspace | i3
          "${mod}+ampersand" = "workspace ${w1}";
          "${mod}+eacute" = "workspace ${w2}";
          "${mod}+quotedbl" = "workspace ${w3}";
          "${mod}+apostrophe" = "workspace ${w4}";
          "${mod}+parenleft" = "workspace  ${w5}";
          "${mod}+minus" = "workspace ${w6}";
          "${mod}+egrave" = "workspace ${w7}";
          "${mod}+underscore" = "workspace ${w8}";
          "${mod}+ccedilla" = "workspace ${w9}";
          "${mod}+agrave" = "workspace ${w0}";

          # # Move focused container to workspace
          # # || Super+Shift+[0-9] || Move focused to another workspace | i3
          "${mod}+Shift+ampersand" = "move container to workspace ${w1}";
          "${mod}+Shift+eacute" = "move container to workspace ${w2}";
          "${mod}+Shift+quotedbl" = "move container to workspace ${w3}";
          "${mod}+Shift+apostrophe" = "move container to workspace ${w4}";
          "${mod}+Shift+parenleft" = "move container to workspace ${w5}";
          "${mod}+Shift+minus" = "move container to workspace ${w6}";
          "${mod}+Shift+egrave" = "move container to workspace ${w7}";
          "${mod}+Shift+underscore" = "move container to workspace ${w8}";
          "${mod}+Shift+ccedilla" = "move container to workspace ${w9}";
          "${mod}+Shift+agrave" = "move container to workspace ${w0}";

          # # # || Super+w || Move workspace to monitor | i3
          "${mod}+w" = "mode move_workspace";

          # "${mod}+r mode "resize"
          "${mod}+r" = "mode resize";
        };

        modes = {
          resize = {
            "Left" = "resize shrink width 30px or 10ppt";
            "Down" = "resize grow height 30px or 10ppt";
            "Up" = "resize shrink height 30px or 10ppt";
            "Right" = "resize grow width 30px or 10ppt";

            "Return" = "mode default";
            "Escape" = "mode default";
          };

          move_workspace = {
            "Left" = "move workspace to output left";
            "Down" = "move workspace to output down";
            "Up" = "move workspace to output up";
            "Right" = "move workspace to output right";

            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };


        bars = [
          {
            #mode = "hide";
            position = "top";
            statusCommand = "py3status -c .config/py3status.conf";

            colors = {
              background = hexPalette.normal.black;
            };
          }
        ];

        startup = [
          {
            command = "${xidlehook} --not-when-fullscreen --timer ${toString lockTime} '${lockCmd}' ''";
            always = false;
            notification = false;
          }
          {
            command = "${feh} --bg-scale '${config.wallpaper}'";
            always = false;
            notification = false;
          }
          #   {
          #   command = " systemctl - -user restart polybar ";
          #   always = true;
          #   notification = false;
          # }
        ];

        assigns = {
          "${w2}" = [
            { class = "Spotify"; }
          ];
          "${w3}" = [
            { class = "Discord"; }
          ];
          "${w7}" = [
            { class = "Google-chrome"; }
          ];
          "${w9}" = [
            { class = "VSCodium"; }
          ];
        };

        floating = {
          border = 1;
          titlebar = false;
          criteria = [
            { class = "pulsemixer"; }
            { class = "bashmount"; }
            { class = ".gnuradio-companion-wrapped"; }
            # SDR
            { class = "gqrx"; }
            { class = "SDRangel"; }
            { class = "qradiolink"; }
            { class = "SDRHunter"; }
            { class = "SDR++.*"; }

          ];
        };

        #for_window [class="pulsemixer"] floating enable border pixel $border
      };
    };
  };
}
