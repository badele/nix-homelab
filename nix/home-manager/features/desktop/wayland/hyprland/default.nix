{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  # Launch automatically hyprland after autologin
  programs = {
    zsh.loginExtra = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
        sleep 5
      fi
    '';
  };

  wayland.windowManager.hyprland =
    let
      inherit (config.colorscheme) colors;

      grimblast = "${inputs.hyprwm-contrib.packages.${pkgs.system}.grimblast}/bin/grimblast";
      flameshot = "${pkgs.light}/bin/flameshot";

      light = "${pkgs.light}/bin/light";
      mako = "${pkgs.mako}/bin/mako";
      makoctl = "${pkgs.mako}/bin/makoctl";
      neomutt = "${pkgs.neomutt}/bin/neomutt";
      pactl = "${pkgs.pulseaudio}/bin/pactl";
      pass-wofi = "${pkgs.pass-wofi}/bin/pass-wofi";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      playerctld = "${pkgs.playerctl}/bin/playerctld";
      swaybg = "${pkgs.swaybg}/bin/swaybg";
      swayidle = "${pkgs.swayidle}/bin/swayidle";
      swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      wofi = "${pkgs.wofi}/bin/wofi";

      terminal = "${pkgs.kitty}/bin/kitty";
      termcmd = class: cmd: "${terminal} --class ${class}} bash -c ${cmd}";

      spotify = "${pkgs.spotify}/bin/spotify";
      ncspot = "${pkgs.ncspot}/bin/ncspot";
      firefox = "${pkgs.firefox}/bin/firefox";
      termcava = termcmd "cava" "cava";
      termncspot = termcmd "ncspot" "ncspot";
    in
    {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default;
      extraConfig = (builtins.concatStringsSep "\n" (lib.forEach config.monitors (m: ''
        monitor=${m.name},${toString m.width}x${toString m.height}@${toString m.refreshRate},${toString m.x}x${toString m.y},${if m.enabled then "1" else "0"}
        ${lib.optionalString (m.workspace != null)"workspace=${m.name},${m.workspace}"}
      ''))) +
      ''
        general {
          main_mod=SUPER
          gaps_in=5
          gaps_out=10
          border_size=1
          col.active_border=0xff${colors.base09}
          col.inactive_border=0xff${colors.base01}
          cursor_inactive_timeout=4
        }

        decoration {
          active_opacity=0.9
          inactive_opacity=0.65
          fullscreen_opacity=1.0
          blur=true
          blur_size=6
          blur_passes=3
          blur_new_optimizations=true
          blur_ignore_opacity=true
          drop_shadow=true
          shadow_range=12
          shadow_offset=3 3
          col.shadow=0x44000000
          col.shadow_inactive=0x66000000
        }

        animations {
          enabled=true
          animation=windows,1,4,default,slide
          animation=border,1,5,default
          animation=fade,1,7,default
          animation=workspaces,1,2,default
        }

        dwindle {
          col.group_border_active=0xff${colors.base0B}
          col.group_border=0xff${colors.base04}
          split_width_multiplier=0.7
          preserve_split=1
          no_gaps_when_only=1
        }

        misc {
          no_vfr=false
        }

        input {
          kb_layout=fr
          touchpad {
            #disable_while_typing=true
            natural_scroll=true
            tap-to-click=true
          }
        }

        ######################################################################
        # Bind keys
        ######################################################################

        # Hyprland managment
        bind=SUPER,q,killactive
        bind=SUPERSHIFT,e,exit

        # Mouse binding
        bindm=SUPER,mouse:272,movewindow
        bindm=SUPER,mouse:273,resizewindow

        # Program bindings
        bind=SUPER,Return,exec,${terminal}
        bind=SUPER,w,exec,${makoctl} dismiss

        # Screenshots
        bind=,Print,exec,${grimblast} --notify copysave area
        bind=SHIFT,Print,exec,${grimblast} --notify copysave active
        bind=CONTROL,Print,exec,${grimblast} --notify copysave screen
        bind=SUPER,Print,exec,${grimblast} --notify copysave window
        bind=ALT,Print,exec,${grimblast} --notify copysave output

        bind=SUPER,space,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%
        bind=SUPER,d,exec,${wofi} -S run

        # Security
        bind=SUPERSHIFT,p,exec,${pass-wofi}
        bind=SUPER,l,exec,${swaylock} -S
        bind=SUPER,l,exec,${playerctl} play-pause

        # Brightness
        bind=,XF86MonBrightnessUp,exec,${light} -A 10
        bind=,XF86MonBrightnessDown,exec,${light} -U 10

        # Audio
        bind=,XF86AudioNext,exec,${playerctl} next
        bind=,XF86AudioPrev,exec,${playerctl} previous
        bind=SUPER,p,exec,${playerctl} play-pause
        bind=,XF86AudioPlay,exec,${playerctl} play-pause
        bind=,XF86AudioStop,exec,${playerctl} stop
        bind=ALT,XF86AudioNext,exec,${playerctld} shift
        bind=ALT,XF86AudioPrev,exec,${playerctld} unshift
        bind=ALT,XF86AudioPlay,exec,${systemctl} --user restart playerctld
        bind=,XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%
        bind=,XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%
        bind=,XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle
        bind=SHIFT,XF86AudioMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle
        bind=,XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle

        # Window managment
        bind=SUPER,s,togglesplit
        bind=SUPER,f,fullscreen,1
        bind=SUPERSHIFT,f,fullscreen,0
        bind=SUPERSHIFT,space,togglefloating

        # Resize
        bind=SUPERCONTROL,left,splitratio,-0.25
        bind=SUPERCONTROL,right,splitratio,0.25

        bind=SUPER,left,movefocus,l
        bind=SUPER,right,movefocus,r
        bind=SUPER,up,movefocus,u
        bind=SUPER,down,movefocus,d

        bind=SUPERSHIFT,left,movewindow,l
        bind=SUPERSHIFT,right,movewindow,r
        bind=SUPERSHIFT,up,movewindow,u
        bind=SUPERSHIFT,down,movewindow,d

        bind=SUPERCONTROL,left,focusmonitor,l
        bind=SUPERCONTROL,right,focusmonitor,r
        bind=SUPERCONTROL,up,focusmonitor,u
        bind=SUPERCONTROL,down,focusmonitor,d

        bind=SUPERCONTROL,ampersand,focusmonitor,DP-1
        bind=SUPERCONTROL,eacute,focusmonitor,DP-2
        bind=SUPERCONTROL,quotedbl,focusmonitor,DP-3

        bind=SUPERCONTROLSHIFT,left,movewindow,mon:l
        bind=SUPERCONTROLSHIFT,right,movewindow,mon:r
        bind=SUPERCONTROLSHIFT,up,movewindow,mon:u
        bind=SUPERCONTROLSHIFT,down,movewindow,mon:d

        bind=SUPERCONTROLSHIFT,ampersand,movewindow,mon:DP-1
        bind=SUPERCONTROLSHIFT,eacute,movewindow,mon:DP-2
        bind=SUPERCONTROLSHIFT,quotedbl,movewindow,mon:DP-3

        bind=SUPERALT,left,movecurrentworkspacetomonitor,l
        bind=SUPERALT,right,movecurrentworkspacetomonitor,r
        bind=SUPERALT,up,movecurrentworkspacetomonitor,u
        bind=SUPERALT,down,movecurrentworkspacetomonitor,d

        bind=SUPER,u,togglespecialworkspace
        bind=SUPERSHIFT,u,movetoworkspace,special

        bind=SUPER,ampersand,workspace,01
        bind=SUPER,eacute,workspace,02
        bind=SUPER,quotedbl,workspace,03
        bind=SUPER,apostrophe,workspace,04
        bind=SUPER,parenleft,workspace,05
        bind=SUPER,minus,workspace,06
        bind=SUPER,egrave,workspace,07
        bind=SUPER,underscore,workspace,08
        bind=SUPER,ccedilla,workspace,09
        bind=SUPER,agrave,workspace,10

        bind=SUPERSHIFT,ampersand,movetoworkspacesilent,01
        bind=SUPERSHIFT,eacute,movetoworkspacesilent,02
        bind=SUPERSHIFT,quotedbl,movetoworkspacesilent,03
        bind=SUPERSHIFT,apostrophe,movetoworkspacesilent,04
        bind=SUPERSHIFT,parenleft,movetoworkspacesilent,05
        bind=SUPERSHIFT,minus,movetoworkspacesilent,06
        bind=SUPERSHIFT,egrave,movetoworkspacesilent,07
        bind=SUPERSHIFT,underscore,movetoworkspacesilent,08
        bind=SUPERSHIFT,ccedilla,movetoworkspacesilent,09
        bind=SUPERSHIFT,agrave,movetoworkspacesilent,10

        ######################################################################
        # Launch apps & window rules
        ######################################################################
        # Launch
        exec-once=waybar
        exec=${swaybg} -i ${config.wallpaper} --mode fill
        exec-once=${mako}
        exec-once=${swayidle} -w
        exec-once=${termcava}
        exec-once=${firefox}
        exec-once=${termncspot}

        # Use `hyprctl clients` cmd for getting window informations
        # Floating
        windowrule=float,class:cava
        windowrule=float,class:ncspot
        windowrule=float,pavucontrol

        # Windows
        windowrule=workspace 1,class:cava
        windowrule=workspace 1,class:ncspot
        windowrule=workspace 3 silent,Discord
        windowrule=workspace 7 silent,firefox
        windowrule=workspace 9 silent,codium-url-handler
      '';
    };
}
