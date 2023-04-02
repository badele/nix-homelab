{ config, lib, pkgs, ... }:

let
  cfg = config.xsession.windowManager.i3.config;

  py3status-conf = import ./py3status.nix { inherit py3status-conf; };

  # pythonPackages = (pkgs.python310.withPackages (p: with p; [
  #   normalizer
  #   py3status
  # ])).override
  #   (args: { ignoreCollisions = true; });

  lockTime = 4 * 60; # TODO: configurable desktop (10 min)/laptop (4 min)

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

  flameshot = "${pkgs.flameshot}/bin/flameshot";
  peek = "${pkgs.peek}/bin/peek";
  #light = "${pkgs.light}/bin/light";
  # mako = "${pkgs.mako}/bin/mako";
  # makoctl = "${pkgs.mako}/bin/makoctl";
  # neomutt = "${pkgs.neomutt}/bin/neomutt";
  # pactl = "${pkgs.pulseaudio}/bin/pactl";
  # pass-wofi = "${pkgs.pass-wofi}/bin/pass-wofi";
  # playerctl = "${pkgs.playerctl}/bin/playerctl";
  # playerctld = "${pkgs.playerctl}/bin/playerctld";
  # swaybg = "${pkgs.swaybg}/bin/swaybg";
  # swayidle = "${pkgs.swayidle}/bin/swayidle";
  py3status = "${pkgs.python3Packages.py3status}/bin/py3status";
  i3lock = "${pkgs.i3lock-color}/bin/i3lock-color";
  xidlehook = "${pkgs.xidlehook}/bin/xidlehook";
  lockCmd = "${i3lock} --blur 5";
  # swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
  # systemctl = "${pkgs.systemd}/bin/systemctl";
  rofi = "${pkgs.rofi}/bin/rofi";

  terminal = "${pkgs.wezterm}/bin/wezterm";
  # termcmd = class: cmd: "${terminal} --class ${class}} bash -c ${cmd}";

  # spotify = "${pkgs.spotify}/bin/spotify";
  # ncspot = "${pkgs.ncspot}/bin/ncspot";
  # firefox = "${pkgs.firefox}/bin/firefox";
  # termcava = termcmd "cava" "cava";
  # termncspot = termcmd "ncspot" "ncspot";

in
{

  imports = [
    ../rofi.nix
    ./py3status.nix
  ];

  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        modifier = mod;
        terminal = terminal;

        fonts = [ "Source Code Pro" "DejaVu Sans Mono, FontAwesome 6" ];

        focus = {
          newWindow = "smart";
        };

        keybindings = {
          # Shortcut
          # || Super+Return || Launch new terminal | i3
          # || Super+Shift+r || Restart i3 | i3
          # || Super+q || Kill a window | i3
          # || Super+k || Show where is rocky | i3
          "${mod}+Return" = "exec ${cfg.terminal}";
          "${mod}+Shift+r" = "restart; exec notify-send 'i3 restarted'";
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
          "${mod}+space" = "exec --no-startup-id ${rofi} -show-icons -show drun";

          # # Screenshot
          # # || Print || Take a desktop screenshot | i3
          # # || Shift+Print || Take a selection screenshot | i3
          # # || Super+c || Color picker | i3
          "Print" = "exec --no-startup-id ${flameshot} gui";
          "Shift+Print" = "--release exec --no-startup-id ${peek}";
          "${mod}+c" = "--release exec ~/.local/bin/colorpicker";

          # # Audio
          # # || Super+p || Pause media player | i3
          # # || Super+m || Show TUI pulseaudio mixer | i3
          # # || Super+d || Show TUI mount disk | i3
          "XF86AudioMute" = "exec --no-startup-id ~/.local/bin/mixer output mute";
          "XF86AudioMicMute" = "exec --no-startup-id ~/.local/bin/mixer mic mute";
          "XF86AudioLowerVolume" = "exec --no-startup-id ~/.local/bin/mixer output down";
          "XF86AudioRaiseVolume" = "exec --no-startup-id ~/.local/bin/mixer output up";
          "${mod}+p" = "exec --no-startup-id ~/.local/bin/mediactl play-pause";
          "${mod}+m" = "exec --no-startup-id $terminal start --class pulsemixer -- pulsemixer";
          "${mod}+d" = "exec --no-startup-id $terminal start --class bashmount -- bashmount";

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
          }
        ];

        startup = [
          {
            command = "${xidlehook} --not-when-fullscreen --timer ${toString lockTime} '${lockCmd}' ''";
            always = false;
            notification = false;
          }
          #   {
          #   command = " systemctl - -user restart polybar ";
          #   always = true;
          #   notification = false;
          # }
        ];
      };
    };
  };
}
