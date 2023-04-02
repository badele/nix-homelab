# ██████╗ ██████╗  ██████╗  ██████╗ ████████╗
# ██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝
# ██████╔╝██████╔╝██║   ██║██║   ██║   ██║   
# ██╔══██╗██╔══██╗██║   ██║██║   ██║   ██║   
# ██████╔╝██║  ██║╚██████╔╝╚██████╔╝   ██║   
# ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   


{ ... }:
{
  programs.broot = {
    enable = true; ## Alias br alias
    settings = {
      default_flags = "sdp";
      date_time_format = "%d/%m/%Y %R";
      show_selection_mark = true;
      max_panels_count = 2;

      verbs = [
        {
          invocation = "goto_home";
          shortcut = "gh";
          execution = ":focus ~/";
          "leave_broot" = false;
        }
        {
          invocation = "search_image";
          shortcut = "si";
          cmd = ":focus ~;/.jpg|.jpeg|.png|.gif;:preview_image";
          "leave_broot" = false;
        }
        {
          invocation = "goto_wallpapers";
          shortcut = "gw";
          cmd = ":focus ~/wallpapers;/.jpg|.jpeg|.png|.gif;:preview_image";
          "leave_broot" = false;
        }
        {
          invocation = "goto_docs";
          shortcut = "gd";
          execution = ":focus ~/docs";
          "leave_broot" = false;
        }
        {
          invocation = "goto_medias";
          shortcut = "gm";
          execution = ":focus /run/media/badele/";
          "leave_broot" = false;
        }
        {
          invocation = "change_colors_scheme";
          shortcut = "ccs";
          key = "ctrl-b";
          external = "my-set-color-scheme-from-image \"{file}\"";
          "leave_broot" = false;
        }
        {
          invocation = "edit";
          shortcut = "e";
          execution = "$EDITOR +{line} {file}";
          "leave_broot" = false;
        }
        {
          invocation = "create {subpath}";
          execution = "$EDITOR {directory}/{subpath}";
          "leave_broot" = false;
        }
        {
          invocation = "git_diff";
          shortcut = "gd";
          "leave_broot" = false;
          execution = "git difftool -y {file}";
        }
        {
          invocation = "terminal";
          key = "ctrl-t";
          execution = "$SHELL";
          "set_working_dir" = true;
          "leave_broot" = false;
        }
      ];
    };
  };

  #     xdg.configFile = {
  #     "broot/verbs.hjson".source = ./verbs.hjson;
  #   };    
}
