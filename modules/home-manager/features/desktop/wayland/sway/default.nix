{ inputs, lib, config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;

  cfg = config.wayland.windowManager.sway;

  mod = "Mod4";
  left = "Left";
  right = "Right";
  up = "Up";
  down = "Down";

  # Exec function
  exec = cmd: "exec '${cmd}'";

  grimblast = "${inputs.hyprwm-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast";

  light = "${pkgs.light}/bin/light";
  mako = "${pkgs.mako}/bin/mako";
  makoctl = "${pkgs.mako}/bin/makoctl";
  neomutt = "${pkgs.neomutt}/bin/neomutt";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  pass-wofi = "${pkgs.pass-wofi}/bin/pass-wofi";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";
  qutebrowser = "${pkgs.qutebrowser}/bin/qutebrowser";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
  swayidle = "${pkgs.swayidle}/bin/swayidle";
  swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  wofi = "${pkgs.wofi}/bin/wofi";
  rofi = "${pkgs.rofi}/bin/rofi";

  terminal = "kitty";
  terminal-spawn = cmd: "${terminal} $SHELL -i -c ${cmd}";


in
{
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  programs = {
    zsh.loginExtra = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';
  };

  wayland.windowManager.sway =
    {
      enable = true;

      config = {
        modifier = mod;
        terminal = terminal;

        # https://man.archlinux.org/man/xkeyboard-config.7.en
        # swaymsg -t get_inputs
        input = {
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_layout = "fr";
            xkb_options = "grp_led:num";
          };

          "2:8:AlpsPS\/2_ALPS_GlidePoint" = {
            tap = "enabled";
            natural_scroll = "enabled";
          };
          "*" = {
            xkb_layout = "fr";
            xkb_options = "grp_led:num";
          };
        };

        # Disable i3status bar
        bars = [ ];
        modes.resize = {
          Escape = "mode default";
          Return = "mode default";
          "${down}" = "resize grow height 10 px or 10 ppt";
          "${left}" = "resize shrink width 10 px or 10 ppt";
          "${right}" = "resize grow width 10 px or 10 ppt";
          "${up}" = "resize shrink height 10 px or 10 ppt";
        };

        gaps = {
          outer = 5;
          inner = 5;
          smartGaps = true;
          smartBorders = "no_gaps";
        };

        colors = {
          background = "#ffffff";
          urgent = {
            background = "#${colors.base08}";
            border = "#${colors.base08}";
            childBorder = "#${colors.base08}";
            indicator = "#${colors.base08}";
            text = "#ffffff";
          };
          focused = {
            background = "#${colors.base02}";
            border = "#${colors.base02}";
            childBorder = "#${colors.base02}";
            indicator = "#${colors.base02}";
            text = "#ffffff";
          };
          focusedInactive = {
            background = "#${colors.base01}";
            border = "#${colors.base01}";
            childBorder = "#${colors.base01}";
            indicator = "#${colors.base01}";
            text = "#ffffff";
          };
          unfocused = {
            background = "#${colors.base01}";
            border = "#${colors.base01}";
            childBorder = "#${colors.base01}";
            indicator = "#${colors.base01}";
            text = "#888888";
          };
        };

        # Kes
        # use wev tool for showing the key code
        bindkeysToCode = true;
        keybindings =
          let
            w = "workspace number";
          in
          {
            "${mod}+Return" = exec "${cfg.config.terminal}";
            "${mod}+q" = "kill";
            "${mod}+space" = exec "${cfg.config.menu}";

            # Keyboard controls (brightness, media, sound, etc)
            "XF86MonBrightnessUp" = exec "${light} -A 10";
            "XF86MonBrightnessDown" = exec "${light} -U 10";

            "${mod}+${left}" = "focus left";
            "${mod}+${down}" = "focus down";
            "${mod}+${up}" = "focus up";
            "${mod}+${right}" = "focus right";

            "${mod}+Shift+${cfg.config.left}" = "move left";
            "${mod}+Shift+${cfg.config.down}" = "move down";
            "${mod}+Shift+${cfg.config.up}" = "move up";
            "${mod}+Shift+${cfg.config.right}" = "move right";

            "${mod}+Shift+${left}" = "move left";
            "${mod}+Shift+${down}" = "move down";
            "${mod}+Shift+${up}" = "move up";
            "${mod}+Shift+${right}" = "move right";

            "${mod}+h" = "splith";
            "${mod}+v" = "splitv";
            "${mod}+f" = "fullscreen toggle";
            "${mod}+a" = "focus parent";

            "${mod}+s" = "layout stacking";
            "${mod}+w" = "layout tabbed";
            "${mod}+e" = "layout toggle split";

            "${mod}+Shift+space" = "floating toggle";
            #          "${mod}+space" = "focus mode_toggle";

            "${mod}+ampersand" = "${w} 1";
            "${mod}+eacute" = "${w} 2";
            "${mod}+quotedbl" = "${w} 3";
            "${mod}+apostrophe" = "${w} 4";
            "${mod}+parenleft" = "${w} 5";
            "${mod}+minus" = "${w} 6";
            "${mod}+egrave" = "${w} 7";
            "${mod}+underscore" = "${w} 8";
            "${mod}+ccedilla" = "${w} 9";
            "${mod}+agrave" = "${w} 0";

            "${mod}+Shift+ampersand" =
              "move container to ${w} 1";
            "${mod}+Shift+eacute" =
              "move container to ${w} 2";
            "${mod}+Shift+quotedbl" =
              "move container to ${w} 3";
            "${mod}+Shift+apostrophe" =
              "move container to ${w} 4";
            "${mod}+Shift+parenleft" =
              "move container to ${w} 5";
            "${mod}+Shift+minus" =
              "move container to ${w} 6";
            "${mod}+Shift+egrave" =
              "move container to ${w} 7";
            "${mod}+Shift+underscore" =
              "move container to ${w} 8";
            "${mod}+Shift+ccedilla" =
              "move container to ${w} 9";
            "${mod}+Shift+agrave" =
              "move container to ${w} 0";

            # "${mod}+Shift+minus" = "move scratchpad";
            # "${mod}+minus" = "scratchpad show";

            "${mod}+Shift+r" = "reload";
            "${mod}+Shift+e" =
              #exec "swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";
              exec "swaymsg exit";
            "${mod}+r" = "mode resize";
          };

        startup = [
          # {
          #   command = "${kanshi}/bin/kanshi";
          #   always = true;
          # }
          # {
          #   command = "${browser.executable.path}";
          # }
          {
            command = "waybar";
          }
          {
            command = "${swaybg} -i ${config.wallpaper} --mode fill";
          }
          {
            command = "${mako}";
          }
          # {
          #   command = "${swayidle} -w";
          # }
          # {
          #   command = "${wl-clipboard}/bin/wl-paste -t text --watch ${clipman}/bin/clipman store";
          # }
          # {
          #   command = "${clipman}/bin/clipman restore";
          # }
          {
            command = "unset LESS_TERMCAP_mb";
          }
          {
            command = "unset LESS_TERMCAP_md";
          }
          {
            command = "unset LESS_TERMCAP_me";
          }
          {
            command = "unset LESS_TERMCAP_se";
          }
          {
            command = "unset LESS_TERMCAP_so";
          }
          {
            command = "unset LESS_TERMCAP_ue";
          }
          {
            command = "unset LESS_TERMCAP_us";
          }
        ];
      };
    };
}
